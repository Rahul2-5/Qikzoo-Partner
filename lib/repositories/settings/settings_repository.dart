import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/settings/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> getSettings();
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings);
}

class MockSettingsRepository implements SettingsRepository {
  AppSettingsModel _settings = AppSettingsModel.defaults;

  @override
  Future<AppSettingsModel> getSettings() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _settings;
  }

  @override
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    _settings = settings;
    return _settings;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => MockSettingsRepository());
