import '../entities/recurring_expense.dart';

abstract class RecurringRepository {
  Stream<List<RecurringExpense>> watchAll();
  Stream<List<RecurringExpense>> watchActive();
  Future<RecurringExpense?> getById(int id);
  Future<int> create(RecurringExpense recurringExpense);
  Future<void> update(RecurringExpense recurringExpense);
  Future<void> delete(int id);
}
