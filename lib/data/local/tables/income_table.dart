import 'package:drift/drift.dart';

import 'account_table.dart';
import 'category_table.dart';

@DataClassName('IncomeRow')
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get source => text()(); // salary|business|investment|freelance|gift|other
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
