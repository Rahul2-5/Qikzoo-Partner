import 'package:equatable/equatable.dart';

class AppSettingsModel extends Equatable {
  final bool notificationsEnabled;
  final String language;

  const AppSettingsModel({required this.notificationsEnabled, required this.language});

  static const defaults = AppSettingsModel(notificationsEnabled: true, language: 'en');

  AppSettingsModel copyWith({bool? notificationsEnabled, String? language}) => AppSettingsModel(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        language: language ?? this.language,
      );

  @override
  List<Object?> get props => [notificationsEnabled, language];
}
