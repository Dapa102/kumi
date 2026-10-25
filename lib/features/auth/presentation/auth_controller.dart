import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({required this._repository, required this._storage});

  final AuthRepository _repository;
  final TokenStorage _storage;

  AuthStatus _status = AuthStatus.unknown;
  bool _busy = false;
  String? _error;
  String? _userName;

  AuthStatus get status => _status;
  bool get busy => _busy;
  String? get error => _error;
  String? get userName => _userName;

  Future<void> bootstrap() async {
    await _repository.restoreToken();
    final hasSession = await _repository.hasStoredSession();
    _userName = await _storage.readUserName();
    _status = hasSession
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.signInWithGoogle();
      _userName = result?.user.name;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } on NetworkException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Gagal masuk. Coba lagi.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _userName = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by feature controllers when the API answers 401.
  Future<void> handleExpiredSession() async {
    await _repository.clearSession();
    _status = AuthStatus.unauthenticated;
    _error = 'Sesi berakhir, silakan masuk kembali.';
    notifyListeners();
  }
}
