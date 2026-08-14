import '../entities/income.dart';

abstract class IncomeRepository {
  Stream<List<Income>> watchAll();
  Stream<List<Income>> watchByDateRange(DateTime start, DateTime end);
  Future<Income?> getById(int id);
  Future<int> create(Income income);
  Future<void> update(Income income);
  Future<void> delete(int id);
}
