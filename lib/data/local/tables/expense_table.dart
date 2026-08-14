import 'package:drift/drift.dart';

import 'account_table.dart';
import 'category_table.dart';
import 'trip_table.dart';

@DataClassName('ExpenseRow')
@TableIndex(name: 'idx_expense_date', columns: <Symbol>{#date})
@TableIndex(name: 'idx_expense_category', columns: <Symbol>{#categoryId})
@TableIndex(name: 'idx_expense_trip', columns: <Symbol>{#tripId})
@TableIndex(name: 'idx_expense_account', columns: <Symbol>{#accountId})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get title => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get tripId => integer().nullable().references(Trips, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get time => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
