import 'package:drift/drift.dart';

@DataClassName('BudgetRow')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get periodType => text()(); // weekly|monthly|custom
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get totalAmount => real()();
  /// JSON-encoded list of percentages, e.g. "[80,90,100]".
  TextColumn get alertThresholds =>
      text().withDefault(const Constant('[80,90,100]'))();
  DateTimeColumn get createdAt => dateTime()();
}
