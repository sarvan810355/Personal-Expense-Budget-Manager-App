import 'package:drift/drift.dart';

import 'account_table.dart';
import 'category_table.dart';

@DataClassName('RecurringExpenseRow')
class RecurringExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get frequency => text()(); // daily|weekly|monthly|yearly
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
}
