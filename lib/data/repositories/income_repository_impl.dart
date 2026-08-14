import 'package:drift/drift.dart';

import '../../domain/entities/income.dart';
import '../../domain/repositories/income_repository.dart';
import '../local/app_database.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  IncomeRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Income>> watchAll() =>
      _db.incomeDao.watchAll().map(_mapRows);

  @override
  Stream<List<Income>> watchByDateRange(DateTime start, DateTime end) =>
      _db.incomeDao.watchByDateRange(start, end).map(_mapRows);

  @override
  Future<Income?> getById(int id) async {
    final IncomeRow? row = await _db.incomeDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(Income income) {
    return _db.incomeDao.insertIncome(
      IncomesCompanion.insert(
        amount: income.amount,
        source: income.source.name,
        accountId: income.accountId,
        date: income.date,
        categoryId: Value(income.categoryId),
        note: Value(income.note),
        createdAt: income.createdAt,
      ),
    );
  }

  @override
  Future<void> update(Income income) {
    return _db.incomeDao.updateIncome(
      IncomesCompanion(
        id: Value(income.id),
        amount: Value(income.amount),
        source: Value(income.source.name),
        accountId: Value(income.accountId),
        date: Value(income.date),
        categoryId: Value(income.categoryId),
        note: Value(income.note),
        createdAt: Value(income.createdAt),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.incomeDao.deleteIncome(id);

  List<Income> _mapRows(List<IncomeRow> rows) => rows.map(_toEntity).toList();

  Income _toEntity(IncomeRow row) => Income(
        id: row.id,
        amount: row.amount,
        source: IncomeSource.values.firstWhere(
          (IncomeSource s) => s.name == row.source,
          orElse: () => IncomeSource.other,
        ),
        accountId: row.accountId,
        date: row.date,
        createdAt: row.createdAt,
        categoryId: row.categoryId,
        note: row.note,
      );
}
