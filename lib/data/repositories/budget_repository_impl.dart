import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';
import '../local/app_database.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Budget>> watchAll() =>
      _db.budgetDao.watchAll().map((List<BudgetRow> rows) => rows.map(_toEntity).toList());

  @override
  Future<Budget?> getById(int id) async {
    final BudgetRow? row = await _db.budgetDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(Budget budget) {
    return _db.budgetDao.insertBudget(
      BudgetsCompanion.insert(
        name: budget.name,
        periodType: _periodToString(budget.periodType),
        startDate: budget.startDate,
        endDate: budget.endDate,
        totalAmount: budget.totalAmount,
        alertThresholds: Value(jsonEncode(budget.alertThresholds)),
        createdAt: budget.createdAt,
      ),
    );
  }

  @override
  Future<void> update(Budget budget) {
    return _db.budgetDao.updateBudget(
      BudgetsCompanion(
        id: Value(budget.id),
        name: Value(budget.name),
        periodType: Value(_periodToString(budget.periodType)),
        startDate: Value(budget.startDate),
        endDate: Value(budget.endDate),
        totalAmount: Value(budget.totalAmount),
        alertThresholds: Value(jsonEncode(budget.alertThresholds)),
        createdAt: Value(budget.createdAt),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.budgetDao.deleteBudget(id);

  @override
  Stream<List<BudgetCategory>> watchCategoriesForBudget(int budgetId) {
    return _db.budgetDao
        .watchCategoriesForBudget(budgetId)
        .map((List<BudgetCategoryRow> rows) => rows.map(_toAllocationEntity).toList());
  }

  @override
  Future<int> addCategoryAllocation(BudgetCategory allocation) {
    return _db.budgetDao.insertBudgetCategory(
      BudgetCategoriesCompanion.insert(
        budgetId: allocation.budgetId,
        categoryId: allocation.categoryId,
        allocatedAmount: allocation.allocatedAmount,
      ),
    );
  }

  @override
  Future<void> updateCategoryAllocation(BudgetCategory allocation) {
    return _db.budgetDao.updateBudgetCategory(
      BudgetCategoriesCompanion(
        id: Value(allocation.id),
        budgetId: Value(allocation.budgetId),
        categoryId: Value(allocation.categoryId),
        allocatedAmount: Value(allocation.allocatedAmount),
      ),
    );
  }

  @override
  Future<void> removeCategoryAllocation(int id) =>
      _db.budgetDao.deleteBudgetCategory(id);

  Budget _toEntity(BudgetRow row) => Budget(
        id: row.id,
        name: row.name,
        periodType: BudgetPeriodType.values.firstWhere(
          (BudgetPeriodType t) => t.name == row.periodType,
          orElse: () => BudgetPeriodType.monthly,
        ),
        startDate: row.startDate,
        endDate: row.endDate,
        totalAmount: row.totalAmount,
        alertThresholds: (jsonDecode(row.alertThresholds) as List<dynamic>)
            .map((dynamic e) => e as int)
            .toList(),
        createdAt: row.createdAt,
      );

  BudgetCategory _toAllocationEntity(BudgetCategoryRow row) => BudgetCategory(
        id: row.id,
        budgetId: row.budgetId,
        categoryId: row.categoryId,
        allocatedAmount: row.allocatedAmount,
      );

  String _periodToString(BudgetPeriodType type) => type.name;
}
