class AppConfig {
  const AppConfig._();

  /// Base URL of the Kumi API.
  /// Override with:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Google OAuth client ID used as `serverClientId` so the ID token audience
  /// matches the backend configuration.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration splashMinimumDuration = Duration(milliseconds: 1200);
}
