import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/task_repository.dart';

class TasksController extends ChangeNotifier {
  TasksController({
    required this._repository,
    required this._auth,
    required this._notifications,
  });

  final TaskRepository _repository;
  final AuthController _auth;
  final NotificationService _notifications;

  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'all';
  List<TaskItem> _tasks = const [];
  bool _loading = false;
  String? _error;

  DateTime get selectedDate => _selectedDate;
  String get statusFilter => _statusFilter;
  List<TaskItem> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;

  List<TaskItem> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();
  List<TaskItem> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  void setDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    load();
  }

  void shiftDate(int days) {
    setDate(_selectedDate.add(Duration(days: days)));
  }

  void setStatusFilter(String value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _repository.fetchTasks(
        date: _selectedDate,
        status: _statusFilter,
      );
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

  /// Returns the created/updated task, or null when the request failed.
  Future<TaskItem?> saveTask({
    TaskItem? existing,
    required String title,
    String? description,
    required DateTime dueTime,
  }) async {
    try {
      final task = existing == null
          ? await _repository.createTask(
              title: title,
              description: description,
              dueTime: dueTime,
            )
          : await _repository.updateTask(
              id: existing.id,
              title: title,
              description: description,
              dueTime: dueTime,
            );

      if (existing == null) {
        _tasks = [..._tasks, task]
          ..sort((a, b) => a.dueTime.compareTo(b.dueTime));
      } else {
        _tasks = _tasks.map((item) => item.id == task.id ? task : item).toList()
          ..sort((a, b) => a.dueTime.compareTo(b.dueTime));
      }

      await _notifications.scheduleTaskReminder(task);
      notifyListeners();
      return task;
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

  Future<bool> deleteTask(TaskItem task) async {
    try {
      await _repository.deleteTask(task.id);
      _tasks = _tasks.where((item) => item.id != task.id).toList();
      await _notifications.cancelTaskReminder(task.id);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      if (error.isUnauthorized) await _auth.handleExpiredSession();
      _error = error.message;
      notifyListeners();
      return false;
    } on NetworkException catch (error) {
      _error = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<GamificationResult?> toggleTask(TaskItem task) async {
    try {
      final result = await _repository.toggleComplete(task.id);
      _tasks = _tasks
          .map((item) => item.id == task.id ? result.task : item)
          .toList();

      if (result.task.isCompleted) {
        await _notifications.cancelTaskReminder(task.id);
      } else {
        await _notifications.scheduleTaskReminder(result.task);
      }

      notifyListeners();
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
