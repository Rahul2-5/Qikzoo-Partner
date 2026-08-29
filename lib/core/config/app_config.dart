import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// Only used for non-release builds — a release build with no configured
  /// URL fails loudly instead (see below), so this can never silently ship
  /// pointed at the wrong backend if it's ever repointed during development.
  static const _devFallbackApiBaseUrl =
      'https://qikzoo-api.onrender.com/api/v1';

  static String get apiBaseUrl {
    const dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineBaseUrl.isNotEmpty) return dartDefineBaseUrl;

    final dotenvBaseUrl = dotenv.maybeGet('API_BASE_URL');
    if (dotenvBaseUrl != null && dotenvBaseUrl.isNotEmpty) {
      return dotenvBaseUrl;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL must be passed via --dart-define or defined in .env for release builds.',
      );
    }
    return _devFallbackApiBaseUrl;
  }
}
