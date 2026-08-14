import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: <Type>[AppSettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<AppSettingsRow> watchSettings() {
    return (select(appSettingsTable)..where((AppSettingsTable t) => t.id.equals(1)))
        .watchSingle();
  }

  Future<AppSettingsRow> getSettings() {
    return (select(appSettingsTable)..where((AppSettingsTable t) => t.id.equals(1)))
        .getSingle();
  }

  Future<void> updateSettings(AppSettingsTableCompanion companion) async {
    await (update(appSettingsTable)..where((AppSettingsTable t) => t.id.equals(1)))
        .write(companion);
  }
}
