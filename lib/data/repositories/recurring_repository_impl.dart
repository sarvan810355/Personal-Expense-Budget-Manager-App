import 'package:drift/drift.dart';

import '../../domain/entities/recurring_expense.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../local/app_database.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<RecurringExpense>> watchAll() =>
      _db.recurringDao.watchAll().map(_mapRows);

  @override
  Stream<List<RecurringExpense>> watchActive() =>
      _db.recurringDao.watchActive().map(_mapRows);

  @override
  Future<RecurringExpense?> getById(int id) async {
    final RecurringExpenseRow? row = await _db.recurringDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(RecurringExpense recurringExpense) {
    return _db.recurringDao.insertRecurring(
      RecurringExpensesCompanion.insert(
        title: recurringExpense.title,
        amount: recurringExpense.amount,
        categoryId: recurringExpense.categoryId,
        accountId: recurringExpense.accountId,
        frequency: recurringExpense.frequency.name,
        startDate: recurringExpense.startDate,
        nextDate: recurringExpense.nextDate,
        endDate: Value(recurringExpense.endDate),
        active: Value(recurringExpense.active),
        note: Value(recurringExpense.note),
      ),
    );
  }

  @override
  Future<void> update(RecurringExpense recurringExpense) {
    return _db.recurringDao.updateRecurring(
      RecurringExpensesCompanion(
        id: Value(recurringExpense.id),
        title: Value(recurringExpense.title),
        amount: Value(recurringExpense.amount),
        categoryId: Value(recurringExpense.categoryId),
        accountId: Value(recurringExpense.accountId),
        frequency: Value(recurringExpense.frequency.name),
        startDate: Value(recurringExpense.startDate),
        nextDate: Value(recurringExpense.nextDate),
        endDate: Value(recurringExpense.endDate),
        active: Value(recurringExpense.active),
        note: Value(recurringExpense.note),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.recurringDao.deleteRecurring(id);

  List<RecurringExpense> _mapRows(List<RecurringExpenseRow> rows) =>
      rows.map(_toEntity).toList();

  RecurringExpense _toEntity(RecurringExpenseRow row) => RecurringExpense(
        id: row.id,
        title: row.title,
        amount: row.amount,
        categoryId: row.categoryId,
        accountId: row.accountId,
        frequency: RecurringFrequency.values.firstWhere(
          (RecurringFrequency f) => f.name == row.frequency,
          orElse: () => RecurringFrequency.monthly,
        ),
        startDate: row.startDate,
        nextDate: row.nextDate,
        active: row.active,
        endDate: row.endDate,
        note: row.note,
      );
}
