import 'package:drift/drift.dart';

/// Single-row settings table (`id` is always 1).
@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get currencyCode => text().withDefault(const Constant('USD'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  /// JSON-encoded list of percentages, e.g. "[80,90,100]".
  TextColumn get budgetAlertThresholds =>
      text().withDefault(const Constant('[80,90,100]'))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get weekStartDay => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
