import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/income_table.dart';

part 'income_dao.g.dart';

@DriftAccessor(tables: <Type>[Incomes])
class IncomeDao extends DatabaseAccessor<AppDatabase> with _$IncomeDaoMixin {
  IncomeDao(super.db);

  Stream<List<IncomeRow>> watchAll() {
    return (select(incomes)
          ..orderBy(
            [(Incomes t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)],
          ))
        .watch();
  }

  Stream<List<IncomeRow>> watchByDateRange(DateTime start, DateTime end) {
    return (select(incomes)
          ..where((Incomes t) => t.date.isBetweenValues(start, end)))
        .watch();
  }

  Future<IncomeRow?> getById(int id) {
    return (select(incomes)..where((Incomes t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertIncome(IncomesCompanion companion) =>
      into(incomes).insert(companion);

  Future<bool> updateIncome(IncomesCompanion companion) =>
      update(incomes).replace(companion);

  Future<int> deleteIncome(int id) =>
      (delete(incomes)..where((Incomes t) => t.id.equals(id))).go();
}
