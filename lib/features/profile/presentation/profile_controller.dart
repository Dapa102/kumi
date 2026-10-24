import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../tasks/data/task_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({required this._repository, required this._auth});

  final TaskRepository _repository;
  final AuthController _auth;

  UserProfile? _profile;
  List<Achievement> _achievements = const [];
  bool _loading = false;
  String? _error;

  UserProfile? get profile => _profile;
  List<Achievement> get achievements => _achievements;
  bool get loading => _loading;
  String? get error => _error;
  int get earnedCount => _achievements.where((item) => item.earned).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchProfile(),
        _repository.fetchAchievements(),
      ]);
      _profile = results[0] as UserProfile;
      _achievements = results[1] as List<Achievement>;
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

  Future<bool> updateName(String name) async {
    try {
      _profile = await _repository.updateName(name);
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
}
