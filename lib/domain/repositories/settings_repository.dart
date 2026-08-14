import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Stream<AppSettings> watchSettings();
  Future<AppSettings> getSettings();
  Future<void> updateThemeMode(String themeMode);
  Future<void> updateCurrencyCode(String currencyCode);
  Future<void> updateBudgetAlertThresholds(List<int> thresholds);
  Future<void> updateNotificationsEnabled(bool enabled);
  Future<void> updateWeekStartDay(int weekStartDay);
}
