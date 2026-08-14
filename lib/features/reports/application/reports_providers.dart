import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/calculation_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/income.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../income/application/income_providers.dart';

const CalculationService _calculationService = CalculationService();

/// Selectable date ranges for the spending-by-category report.
enum ReportPeriod { thisMonth, lastMonth, last3Months, thisYear }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.thisMonth:
        return 'This month';
      case ReportPeriod.lastMonth:
        return 'Last month';
      case ReportPeriod.last3Months:
        return 'Last 3 months';
      case ReportPeriod.thisYear:
        return 'This year';
    }
  }
}

/// User-selected period for the spending-by-category report, defaulting to
/// the current month.
final StateProvider<ReportPeriod> selectedReportPeriodProvider =
    StateProvider<ReportPeriod>((Ref ref) => ReportPeriod.thisMonth);

/// Inclusive [start, end] window covered by a [ReportPeriod], anchored to
/// now.
({DateTime start, DateTime end}) _rangeFor(ReportPeriod period) {
  final DateTime now = DateTime.now();
  switch (period) {
    case ReportPeriod.thisMonth:
      return (start: AppDateUtils.startOfMonth(now), end: AppDateUtils.endOfMonth(now));
    case ReportPeriod.lastMonth:
      final DateTime lastMonth = DateTime(now.year, now.month - 1);
      return (
        start: AppDateUtils.startOfMonth(lastMonth),
        end: AppDateUtils.endOfMonth(lastMonth),
      );
    case ReportPeriod.last3Months:
      final DateTime start = DateTime(now.year, now.month - 2);
      return (start: AppDateUtils.startOfMonth(start), end: AppDateUtils.endOfMonth(now));
    case ReportPeriod.thisYear:
      return (start: DateTime(now.year), end: AppDateUtils.endOfMonth(now));
  }
}

/// [allExpensesProvider] refiltered to the currently [selectedReportPeriodProvider]
/// window, so the picker doesn't require new repository queries.
final Provider<AsyncValue<List<Expense>>> reportPeriodExpensesProvider =
    Provider<AsyncValue<List<Expense>>>((Ref ref) {
  final ReportPeriod period = ref.watch(selectedReportPeriodProvider);
  final AsyncValue<List<Expense>> expenses = ref.watch(allExpensesProvider);
  return expenses.whenData((List<Expense> data) {
    final ({DateTime start, DateTime end}) range = _rangeFor(period);
    return data
        .where((Expense e) => !e.date.isBefore(range.start) && !e.date.isAfter(range.end))
        .toList();
  });
});

/// Selected-period expenses grouped by category (highest spend first), the
/// same shape as [currentMonthCategoryBreakdownProvider] but over the
/// picker's range instead of a fixed current month.
final Provider<AsyncValue<List<CategorySpend>>> reportCategoryBreakdownProvider =
    Provider<AsyncValue<List<CategorySpend>>>((Ref ref) {
  final AsyncValue<List<Expense>> expenses = ref.watch(reportPeriodExpensesProvider);
  final AsyncValue<List<Category>> categories = ref.watch(allCategoriesProvider);
  if (expenses.isLoading || categories.isLoading) {
    return const AsyncValue.loading();
  }
  if (expenses.hasError) {
    return AsyncValue.error(expenses.error!, expenses.stackTrace!);
  }
  if (categories.hasError) {
    return AsyncValue.error(categories.error!, categories.stackTrace!);
  }
  final Map<int, Category> categoriesById = <int, Category>{
    for (final Category category in categories.value!) category.id: category,
  };
  final Map<Category, double> breakdown =
      _calculationService.categoryBreakdown(expenses.value!, categoriesById);
  final List<CategorySpend> result = <CategorySpend>[
    for (final MapEntry<Category, double> entry in breakdown.entries)
      CategorySpend(category: entry.key, amount: entry.value),
  ]..sort((CategorySpend a, CategorySpend b) => b.amount.compareTo(a.amount));
  return AsyncValue.data(result);
});

/// How many months the income-vs-expense trend chart covers.
const int kTrendMonthCount = 6;

/// One month's income and expense totals for the trend chart.
class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

/// Income vs. expense totals for the last [kTrendMonthCount] months (oldest
/// first), built from [CalculationService.monthlyComparison] and
/// [CalculationService.monthlyIncomeComparison] so the figures match any
/// other screen that reports on the same data.
final Provider<AsyncValue<List<MonthlyTrendPoint>>> monthlyTrendProvider =
    Provider<AsyncValue<List<MonthlyTrendPoint>>>((Ref ref) {
  final AsyncValue<List<Expense>> expenses = ref.watch(allExpensesProvider);
  final AsyncValue<List<Income>> incomes = ref.watch(incomesProvider);
  if (expenses.isLoading || incomes.isLoading) {
    return const AsyncValue.loading();
  }
  if (expenses.hasError) {
    return AsyncValue.error(expenses.error!, expenses.stackTrace!);
  }
  if (incomes.hasError) {
    return AsyncValue.error(incomes.error!, incomes.stackTrace!);
  }
  final Map<DateTime, double> expenseByMonth =
      _calculationService.monthlyComparison(expenses.value!, kTrendMonthCount);
  final Map<DateTime, double> incomeByMonth =
      _calculationService.monthlyIncomeComparison(incomes.value!, kTrendMonthCount);
  final List<MonthlyTrendPoint> points = <MonthlyTrendPoint>[
    for (final DateTime month in expenseByMonth.keys)
      MonthlyTrendPoint(
        month: month,
        income: incomeByMonth[month] ?? 0,
        expense: expenseByMonth[month]!,
      ),
  ];
  return AsyncValue.data(points);
});
