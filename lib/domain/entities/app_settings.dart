import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required String currencyCode,
    required String themeMode,
    required List<int> budgetAlertThresholds,
    required bool notificationsEnabled,
    required int weekStartDay,
  }) = _AppSettings;
}
