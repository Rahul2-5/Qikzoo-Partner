import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const _fallbackApiBaseUrl = 'https://qikzoo-api.onrender.com/api/v1';

  static String get apiBaseUrl {
    const dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineBaseUrl.isNotEmpty) return dartDefineBaseUrl;

    final dotenvBaseUrl = dotenv.maybeGet('API_BASE_URL');
    if (dotenvBaseUrl != null && dotenvBaseUrl.isNotEmpty) {
      return dotenvBaseUrl;
    }

    return _fallbackApiBaseUrl;
  }
}
