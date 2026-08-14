import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/budget_category.dart';
import '../../../domain/entities/expense.dart';

/// Spend for a single category allocation within a budget.
class BudgetCategorySpend {
  const BudgetCategorySpend({required this.allocation, required this.spent});

  final BudgetCategory allocation;
  final double spent;
}

/// Aggregated view of a budget: total spent against [Budget.totalAmount],
/// per-category spend against each [BudgetCategory] allocation, and the
/// expenses that were counted so the detail screen can list them.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.categories,
    required this.expenses,
  });

  final Budget budget;
  final double spent;
  final List<BudgetCategorySpend> categories;
  final List<Expense> expenses;
}

/// Loads a budget's allocations and the expenses in its date range, then
/// sums spend overall and per allocated category. When a budget has no
/// category allocations yet, all expenses in its date range count toward
/// the total.
final FutureProviderFamily<BudgetProgress?, int> budgetProgressProvider =
    FutureProvider.family<BudgetProgress?, int>((Ref ref, int budgetId) async {
  final Budget? budget = await ref.watch(budgetRepositoryProvider).getById(budgetId);
  if (budget == null) {
    return null;
  }

  final List<BudgetCategory> allocations = await ref
      .watch(budgetRepositoryProvider)
      .watchCategoriesForBudget(budgetId)
      .first;
  final List<Expense> expensesInRange = await ref
      .watch(expenseRepositoryProvider)
      .watchByDateRange(budget.startDate, budget.endDate)
      .first;

  final Set<int> allocatedCategoryIds =
      allocations.map((BudgetCategory a) => a.categoryId).toSet();
  final List<Expense> relevant = (allocatedCategoryIds.isEmpty
      ? expensesInRange
      : expensesInRange
          .where((Expense e) => allocatedCategoryIds.contains(e.categoryId)))
      .toList()
    ..sort((Expense a, Expense b) => b.date.compareTo(a.date));

  final double totalSpent =
      relevant.fold<double>(0, (double sum, Expense e) => sum + e.amount);

  final List<BudgetCategorySpend> categorySpend = <BudgetCategorySpend>[
    for (final BudgetCategory allocation in allocations)
      BudgetCategorySpend(
        allocation: allocation,
        spent: expensesInRange
            .where((Expense e) => e.categoryId == allocation.categoryId)
            .fold<double>(0, (double sum, Expense e) => sum + e.amount),
      ),
  ];

  return BudgetProgress(
    budget: budget,
    spent: totalSpent,
    categories: categorySpend,
    expenses: relevant,
  );
});
