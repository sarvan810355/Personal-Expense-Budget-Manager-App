import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expense_table.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: <Type>[Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Stream<List<ExpenseRow>> watchAll() {
    return (select(expenses)
          ..orderBy(
            [(Expenses t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)],
          ))
        .watch();
  }

  Stream<List<ExpenseRow>> watchByDateRange(DateTime start, DateTime end) {
    return (select(expenses)
          ..where((Expenses t) => t.date.isBetweenValues(start, end)))
        .watch();
  }

  Stream<List<ExpenseRow>> watchByTrip(int tripId) {
    return (select(expenses)..where((Expenses t) => t.tripId.equals(tripId)))
        .watch();
  }

  Stream<List<ExpenseRow>> watchByCategory(int categoryId) {
    return (select(expenses)
          ..where((Expenses t) => t.categoryId.equals(categoryId)))
        .watch();
  }

  Future<ExpenseRow?> getById(int id) {
    return (select(expenses)..where((Expenses t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertExpense(ExpensesCompanion companion) =>
      into(expenses).insert(companion);

  Future<bool> updateExpense(ExpensesCompanion companion) =>
      update(expenses).replace(companion);

  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((Expenses t) => t.id.equals(id))).go();
}
