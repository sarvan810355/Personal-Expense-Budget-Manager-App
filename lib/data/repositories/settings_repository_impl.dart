import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../local/app_database.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<AppSettings> watchSettings() =>
      _db.settingsDao.watchSettings().map(_toEntity);

  @override
  Future<AppSettings> getSettings() async =>
      _toEntity(await _db.settingsDao.getSettings());

  @override
  Future<void> updateThemeMode(String themeMode) {
    return _db.settingsDao.updateSettings(
      AppSettingsTableCompanion(themeMode: Value(themeMode)),
    );
  }

  @override
  Future<void> updateCurrencyCode(String currencyCode) {
    return _db.settingsDao.updateSettings(
      AppSettingsTableCompanion(currencyCode: Value(currencyCode)),
    );
  }

  @override
  Future<void> updateBudgetAlertThresholds(List<int> thresholds) {
    return _db.settingsDao.updateSettings(
      AppSettingsTableCompanion(
        budgetAlertThresholds: Value(jsonEncode(thresholds)),
      ),
    );
  }

  @override
  Future<void> updateNotificationsEnabled(bool enabled) {
    return _db.settingsDao.updateSettings(
      AppSettingsTableCompanion(notificationsEnabled: Value(enabled)),
    );
  }

  @override
  Future<void> updateWeekStartDay(int weekStartDay) {
    return _db.settingsDao.updateSettings(
      AppSettingsTableCompanion(weekStartDay: Value(weekStartDay)),
    );
  }

  AppSettings _toEntity(AppSettingsRow row) => AppSettings(
        currencyCode: row.currencyCode,
        themeMode: row.themeMode,
        budgetAlertThresholds: (jsonDecode(row.budgetAlertThresholds) as List<dynamic>)
            .map((dynamic e) => e as int)
            .toList(),
        notificationsEnabled: row.notificationsEnabled,
        weekStartDay: row.weekStartDay,
      );
}
