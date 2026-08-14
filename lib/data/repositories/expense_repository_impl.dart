import 'package:drift/drift.dart';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../local/app_database.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Expense>> watchAll() =>
      _db.expenseDao.watchAll().map(_mapRows);

  @override
  Stream<List<Expense>> watchByDateRange(DateTime start, DateTime end) =>
      _db.expenseDao.watchByDateRange(start, end).map(_mapRows);

  @override
  Stream<List<Expense>> watchByTrip(int tripId) =>
      _db.expenseDao.watchByTrip(tripId).map(_mapRows);

  @override
  Stream<List<Expense>> watchByCategory(int categoryId) =>
      _db.expenseDao.watchByCategory(categoryId).map(_mapRows);

  @override
  Future<Expense?> getById(int id) async {
    final ExpenseRow? row = await _db.expenseDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(Expense expense) {
    return _db.expenseDao.insertExpense(
      ExpensesCompanion.insert(
        amount: expense.amount,
        title: expense.title,
        categoryId: expense.categoryId,
        accountId: expense.accountId,
        tripId: Value(expense.tripId),
        date: expense.date,
        time: Value(expense.time),
        note: Value(expense.note),
        paymentMethod: Value(expense.paymentMethod),
        location: Value(expense.location),
        receiptPath: Value(expense.receiptPath),
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      ),
    );
  }

  @override
  Future<void> update(Expense expense) {
    return _db.expenseDao.updateExpense(
      ExpensesCompanion(
        id: Value(expense.id),
        amount: Value(expense.amount),
        title: Value(expense.title),
        categoryId: Value(expense.categoryId),
        accountId: Value(expense.accountId),
        tripId: Value(expense.tripId),
        date: Value(expense.date),
        time: Value(expense.time),
        note: Value(expense.note),
        paymentMethod: Value(expense.paymentMethod),
        location: Value(expense.location),
        receiptPath: Value(expense.receiptPath),
        createdAt: Value(expense.createdAt),
        updatedAt: Value(expense.updatedAt),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.expenseDao.deleteExpense(id);

  List<Expense> _mapRows(List<ExpenseRow> rows) => rows.map(_toEntity).toList();

  Expense _toEntity(ExpenseRow row) => Expense(
        id: row.id,
        amount: row.amount,
        title: row.title,
        categoryId: row.categoryId,
        accountId: row.accountId,
        tripId: row.tripId,
        date: row.date,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        time: row.time,
        note: row.note,
        paymentMethod: row.paymentMethod,
        location: row.location,
        receiptPath: row.receiptPath,
      );
}
