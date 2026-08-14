import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/calculation_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/income.dart';
import '../../budgets/application/budget_progress.dart';
import '../../income/application/income_providers.dart';

const CalculationService _calculationService = CalculationService();

/// Every expense, unfiltered, used to build the recent-transactions list
/// and to decide whether the dashboard has any data at all.
final StreamProvider<List<Expense>> allExpensesProvider =
    StreamProvider<List<Expense>>(
  (Ref ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);

/// Every budget, unfiltered, used to build the budget progress section and
/// to decide whether the dashboard has any data at all.
final StreamProvider<List<Budget>> allBudgetsProvider =
    StreamProvider<List<Budget>>(
  (Ref ref) => ref.watch(budgetRepositoryProvider).watchAll(),
);

/// All categories, used to resolve both expense- and income-type category
/// labels/icons in the recent-transactions list.
final StreamProvider<List<Category>> allCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// All accounts, used to resolve the account label on each recent income
/// entry.
final StreamProvider<List<Account>> allAccountsProvider =
    StreamProvider<List<Account>>(
  (Ref ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Current calendar month's expenses, used for the summary card and the
/// spending-by-category breakdown.
final StreamProvider<List<Expense>> currentMonthExpensesProvider =
    StreamProvider<List<Expense>>((Ref ref) {
  final DateTime now = DateTime.now();
  return ref.watch(expenseRepositoryProvider).watchByDateRange(
        AppDateUtils.startOfMonth(now),
        AppDateUtils.endOfMonth(now),
      );
});

/// Current calendar month's income entries, used for the summary card.
final StreamProvider<List<Income>> currentMonthIncomesProvider =
    StreamProvider<List<Income>>((Ref ref) {
  final DateTime now = DateTime.now();
  return ref.watch(incomeRepositoryProvider).watchByDateRange(
        AppDateUtils.startOfMonth(now),
        AppDateUtils.endOfMonth(now),
      );
});

/// Combines two [AsyncValue]s into one, propagating loading/error state
/// before falling back to [combine] once both hold data.
AsyncValue<R> _combine2<A, B, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  R Function(A, B) combine,
) {
  if (a.isLoading || b.isLoading) {
    return const AsyncValue.loading();
  }
  if (a.hasError) {
    return AsyncValue.error(a.error!, a.stackTrace!);
  }
  if (b.hasError) {
    return AsyncValue.error(b.error!, b.stackTrace!);
  }
  return AsyncValue.data(combine(a.value as A, b.value as B));
}

/// Current-month income/expense totals and the resulting net balance shown
/// on the dashboard's summary card.
class MonthlySummary {
  const MonthlySummary({required this.totalIncome, required this.totalExpense});

  final double totalIncome;
  final double totalExpense;

  double get net => totalIncome - totalExpense;
}

/// [MonthlySummary] built from [currentMonthIncomesProvider] and
/// [currentMonthExpensesProvider] via [CalculationService].
final Provider<AsyncValue<MonthlySummary>> monthlySummaryProvider =
    Provider<AsyncValue<MonthlySummary>>((Ref ref) {
  final AsyncValue<List<Income>> incomes = ref.watch(currentMonthIncomesProvider);
  final AsyncValue<List<Expense>> expenses = ref.watch(currentMonthExpensesProvider);
  return _combine2(
    incomes,
    expenses,
    (List<Income> i, List<Expense> e) => MonthlySummary(
      totalIncome: _calculationService.totalIncome(i),
      totalExpense: _calculationService.totalExpense(e),
    ),
  );
});

/// One category's current-month spend, for the breakdown list.
class CategorySpend {
  const CategorySpend({required this.category, required this.amount});

  final Category category;
  final double amount;
}

/// Current-month expenses grouped by category (highest spend first), reusing
/// [CalculationService.categoryBreakdown] so the totals match any other
/// screen that reports on the same data.
final Provider<AsyncValue<List<CategorySpend>>> currentMonthCategoryBreakdownProvider =
    Provider<AsyncValue<List<CategorySpend>>>((Ref ref) {
  final AsyncValue<List<Expense>> expenses = ref.watch(currentMonthExpensesProvider);
  final AsyncValue<List<Category>> categories = ref.watch(allCategoriesProvider);
  return _combine2(expenses, categories, (List<Expense> e, List<Category> c) {
    final Map<int, Category> categoriesById = <int, Category>{
      for (final Category category in c) category.id: category,
    };
    final Map<Category, double> breakdown =
        _calculationService.categoryBreakdown(e, categoriesById);
    return <CategorySpend>[
      for (final MapEntry<Category, double> entry in breakdown.entries)
        CategorySpend(category: entry.key, amount: entry.value),
    ]..sort((CategorySpend a, CategorySpend b) => b.amount.compareTo(a.amount));
  });
});

/// Progress (spent vs. allocated, per [budgetProgressProvider]) for every
/// budget, newest first — the same math the Budgets screens use, so
/// figures match exactly.
final Provider<AsyncValue<List<BudgetProgress>>> dashboardBudgetProgressProvider =
    Provider<AsyncValue<List<BudgetProgress>>>((Ref ref) {
  final AsyncValue<List<Budget>> budgets = ref.watch(allBudgetsProvider);
  return budgets.when(
    data: (List<Budget> data) {
      final List<AsyncValue<BudgetProgress?>> progresses = <AsyncValue<BudgetProgress?>>[
        for (final Budget budget in data) ref.watch(budgetProgressProvider(budget.id)),
      ];
      if (progresses.any((AsyncValue<BudgetProgress?> p) => p.isLoading)) {
        return const AsyncValue.loading();
      }
      for (final AsyncValue<BudgetProgress?> p in progresses) {
        if (p.hasError) {
          return AsyncValue.error(p.error!, p.stackTrace!);
        }
      }
      final List<BudgetProgress> resolved = <BudgetProgress>[
        for (final AsyncValue<BudgetProgress?> p in progresses)
          if (p.value != null) p.value!,
      ]..sort((BudgetProgress a, BudgetProgress b) => b.budget.startDate.compareTo(a.budget.startDate));
      return AsyncValue.data(resolved);
    },
    loading: () => const AsyncValue.loading(),
    error: (Object e, StackTrace st) => AsyncValue.error(e, st),
  );
});

/// How many recent transactions the dashboard shows.
const int kRecentTransactionLimit = 8;

/// A single dashboard "recent transactions" row: either an [Expense] or an
/// [Income] entry, unified so both can share one date-sorted list.
class RecentTransaction {
  const RecentTransaction._({required this.date, this.expense, this.income});

  factory RecentTransaction.fromExpense(Expense expense) =>
      RecentTransaction._(date: expense.date, expense: expense);

  factory RecentTransaction.fromIncome(Income income) =>
      RecentTransaction._(date: income.date, income: income);

  final Expense? expense;
  final Income? income;
  final DateTime date;
}

/// The last [kRecentTransactionLimit] expenses/income entries across all
/// time, newest first.
final Provider<AsyncValue<List<RecentTransaction>>> recentTransactionsProvider =
    Provider<AsyncValue<List<RecentTransaction>>>((Ref ref) {
  final AsyncValue<List<Expense>> expenses = ref.watch(allExpensesProvider);
  final AsyncValue<List<Income>> incomes = ref.watch(incomesProvider);
  return _combine2(expenses, incomes, (List<Expense> e, List<Income> i) {
    final List<RecentTransaction> combined = <RecentTransaction>[
      for (final Expense expense in e) RecentTransaction.fromExpense(expense),
      for (final Income income in i) RecentTransaction.fromIncome(income),
    ]..sort((RecentTransaction a, RecentTransaction b) => b.date.compareTo(a.date));
    return combined.take(kRecentTransactionLimit).toList();
  });
});
