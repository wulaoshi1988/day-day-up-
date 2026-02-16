class AppEnv {
  const AppEnv._();

  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co/functions/v1',
  );

  static const String accessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: '',
  );
}
