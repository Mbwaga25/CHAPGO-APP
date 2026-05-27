class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api/v1';
  static const String localUrl = 'http://localhost:5000/api/v1';

  static bool get isLocal => false;

  static String get apiBase => isLocal ? localUrl : baseUrl;
}
