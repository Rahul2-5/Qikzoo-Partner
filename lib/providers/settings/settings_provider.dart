import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/settings/settings_repository.dart';
import '../../models/settings/app_settings_model.dart';

class SettingsNotifier extends AsyncNotifier<AppSettingsModel> {
  @override
  Future<AppSettingsModel> build() => ref.watch(settingsRepositoryProvider).getSettings();

  Future<void> updateSettings(AppSettingsModel settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).updateSettings(settings),
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettingsModel>(
  SettingsNotifier.new,
);
