import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurring_expense_table.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: <Type>[RecurringExpenses])
class RecurringDao extends DatabaseAccessor<AppDatabase> with _$RecurringDaoMixin {
  RecurringDao(super.db);

  Stream<List<RecurringExpenseRow>> watchAll() => select(recurringExpenses).watch();

  Stream<List<RecurringExpenseRow>> watchActive() {
    return (select(recurringExpenses)
          ..where((RecurringExpenses t) => t.active.equals(true)))
        .watch();
  }

  Future<RecurringExpenseRow?> getById(int id) {
    return (select(recurringExpenses)
          ..where((RecurringExpenses t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertRecurring(RecurringExpensesCompanion companion) =>
      into(recurringExpenses).insert(companion);

  Future<bool> updateRecurring(RecurringExpensesCompanion companion) =>
      update(recurringExpenses).replace(companion);

  Future<int> deleteRecurring(int id) => (delete(recurringExpenses)
        ..where((RecurringExpenses t) => t.id.equals(id)))
      .go();
}
