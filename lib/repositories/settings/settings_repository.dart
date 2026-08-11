import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/settings/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> getSettings();
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings);
}

/// There is no backend endpoint for rider app preferences — these are
/// genuinely device-local settings (like push-notification sound), so
/// real persistence here means on-device storage, not a fake in-memory
/// value that resets every time the provider rebuilds.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _notificationsEnabledKey = 'settings_notifications_enabled';
  static const _languageKey = 'settings_language';

  final FlutterSecureStorage _storage;

  @override
  Future<AppSettingsModel> getSettings() async {
    final notificationsRaw = await _storage.read(key: _notificationsEnabledKey);
    final language = await _storage.read(key: _languageKey);
    return AppSettingsModel(
      notificationsEnabled: notificationsRaw == null ? true : notificationsRaw == 'true',
      language: language ?? AppSettingsModel.defaults.language,
    );
  }

  @override
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings) async {
    await Future.wait([
      _storage.write(
        key: _notificationsEnabledKey,
        value: settings.notificationsEnabled.toString(),
      ),
      _storage.write(key: _languageKey, value: settings.language),
    ]);
    return settings;
  }
}

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => LocalSettingsRepository());
