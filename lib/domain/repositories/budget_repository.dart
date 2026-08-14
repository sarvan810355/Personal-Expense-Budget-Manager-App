import '../entities/budget.dart';
import '../entities/budget_category.dart';

abstract class BudgetRepository {
  Stream<List<Budget>> watchAll();
  Future<Budget?> getById(int id);
  Future<int> create(Budget budget);
  Future<void> update(Budget budget);
  Future<void> delete(int id);

  Stream<List<BudgetCategory>> watchCategoriesForBudget(int budgetId);
  Future<int> addCategoryAllocation(BudgetCategory allocation);
  Future<void> updateCategoryAllocation(BudgetCategory allocation);
  Future<void> removeCategoryAllocation(int id);
}
