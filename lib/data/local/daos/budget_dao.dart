import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/budget_category_table.dart';
import '../tables/budget_table.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: <Type>[Budgets, BudgetCategories])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<BudgetRow>> watchAll() {
    return (select(budgets)
          ..orderBy(
            [(Budgets t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)],
          ))
        .watch();
  }

  Future<BudgetRow?> getById(int id) {
    return (select(budgets)..where((Budgets t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertBudget(BudgetsCompanion companion) =>
      into(budgets).insert(companion);

  Future<bool> updateBudget(BudgetsCompanion companion) =>
      update(budgets).replace(companion);

  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((Budgets t) => t.id.equals(id))).go();

  Stream<List<BudgetCategoryRow>> watchCategoriesForBudget(int budgetId) {
    return (select(budgetCategories)
          ..where((BudgetCategories t) => t.budgetId.equals(budgetId)))
        .watch();
  }

  Future<int> insertBudgetCategory(BudgetCategoriesCompanion companion) =>
      into(budgetCategories).insert(companion);

  Future<bool> updateBudgetCategory(BudgetCategoriesCompanion companion) =>
      update(budgetCategories).replace(companion);

  Future<int> deleteBudgetCategory(int id) => (delete(budgetCategories)
        ..where((BudgetCategories t) => t.id.equals(id)))
      .go();
}
