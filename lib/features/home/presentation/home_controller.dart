import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../tasks/data/task_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({required this._repository, required this._auth});

  final TaskRepository _repository;
  final AuthController _auth;

  UserProfile? _profile;
  List<TaskItem> _tasks = const [];
  String? _dialogText;
  int? _lastDialogId;
  bool _loading = false;
  String? _error;
  bool _celebrating = false;

  UserProfile? get profile => _profile;
  List<TaskItem> get tasks => _tasks;
  String? get dialogText => _dialogText;
  bool get loading => _loading;
  String? get error => _error;
  bool get celebrating => _celebrating;

  int get todayTotal => _tasks.length;
  int get todayCompleted => _tasks.where((task) => task.isCompleted).length;

  List<TaskItem> get upcomingTasks {
    final pending = _tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) => a.dueTime.compareTo(b.dueTime));
    return pending.take(3).toList();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final results = await Future.wait([
        _repository.fetchProfile(),
        _repository.fetchTasks(date: today),
      ]);
      _profile = results[0] as UserProfile;
      _tasks = results[1] as List<TaskItem>;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _auth.handleExpiredSession();
      } else {
        _error = error.message;
      }
    } on NetworkException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> tapMascot() async {
    final context = _resolveContext();
    try {
      final dialog = await _repository.fetchDialog(context: context, excludeId: _lastDialogId);
      _lastDialogId = dialog.id;
      _dialogText = dialog.text;
    } catch (_) {
      _dialogText = _fallbackDialog(context);
    }
    notifyListeners();
  }

  String _resolveContext() {
    if (_celebrating) return 'task_done';
    if (_tasks.isEmpty) return 'idle';
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    return 'night';
  }

  String _fallbackDialog(String context) {
    switch (context) {
      case 'morning':
        return 'Selamat pagi! Hari ini kita mulai pelan-pelan, ya.';
      case 'afternoon':
        return 'Setengah hari sudah lewat. Satu langkah kecil masih berarti.';
      case 'night':
        return 'Waktunya istirahat. Besok kita coba lagi, ya.';
      case 'task_done':
        return 'Yeay! Satu tugas selesai. Aku bangga sama kamu!';
      default:
        return 'Belum ada tugas hari ini. Mau tambah satu?';
    }
  }

  Future<GamificationResult?> toggleTask(TaskItem task) async {
    try {
      final result = await _repository.toggleComplete(task.id);
      _tasks = _tasks
          .map((item) => item.id == task.id ? result.task : item)
          .toList();
      _profile = _profile == null
          ? null
          : UserProfile(
              id: _profile!.id,
              email: _profile!.email,
              name: _profile!.name,
              pictureUrl: _profile!.pictureUrl,
              currentStreak: result.gamification.currentStreak,
              lastCompletedDate: _profile!.lastCompletedDate,
              totalTasks: _profile!.totalTasks,
              completedTasks: _profile!.completedTasks,
              completedToday: todayCompleted,
              completionRate: _profile!.completionRate,
            );

      if (result.task.isCompleted) {
        _celebrating = true;
        _dialogText = null;
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        _celebrating = false;
        await tapMascot();
      } else {
        notifyListeners();
      }
      return result.gamification;
    } on ApiException catch (error) {
      if (error.isUnauthorized) await _auth.handleExpiredSession();
      _error = error.message;
      notifyListeners();
      return null;
    } on NetworkException catch (error) {
      _error = error.message;
      notifyListeners();
      return null;
    }
  }
}
