import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository({required this._api, required this._storage});

  final ApiClient _api;
  final TokenStorage _storage;

  Future<bool> hasStoredSession() async {
    final token = await _storage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthResult?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(serverClientId: AppConfig.googleClientId);

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const NetworkException('ID Token Google tidak tersedia.');
    }

    final response = await _api.post('/api/v1/auth/google', body: {'id_token': idToken});
    final result = AuthResult.fromJson(response as Map<String, dynamic>);

    await _storage.saveToken(result.accessToken);
    await _storage.saveUserName(result.user.name);
    _api.setToken(result.accessToken);
    return result;
  }

  Future<void> restoreToken() async {
    final token = await _storage.readToken();
    _api.setToken(token);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore: local session cleanup must always succeed.
    }
    await _storage.clear();
    _api.setToken(null);
  }

  Future<void> clearSession() async {
    await _storage.clear();
    _api.setToken(null);
  }
}
