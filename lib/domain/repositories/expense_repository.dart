import '../entities/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchAll();
  Stream<List<Expense>> watchByDateRange(DateTime start, DateTime end);
  Stream<List<Expense>> watchByTrip(int tripId);
  Stream<List<Expense>> watchByCategory(int categoryId);
  Future<Expense?> getById(int id);
  Future<int> create(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(int id);
}
