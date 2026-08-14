import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/income.dart';
import '../utils/date_utils.dart';

/// Centralized financial math (§8 of ARCHITECTURE.md). Every screen that
/// shows a total, a percentage, or a breakdown calls into this service
/// instead of computing it inline, so the formulas exist in exactly one
/// place and are unit-tested in isolation from widgets/providers.
class CalculationService {
  const CalculationService();

  double totalExpense(List<Expense> expenses) =>
      expenses.fold(0, (double sum, Expense e) => sum + e.amount);

  double totalIncome(List<Income> incomes) =>
      incomes.fold(0, (double sum, Income i) => sum + i.amount);

  double savings(double income, double expense) => income - expense;

  double budgetRemaining(double budgetAmount, double spent) =>
      budgetAmount - spent;

  /// Percentage of a budget consumed. Returns 0 when [budgetAmount] is 0
  /// rather than dividing by zero.
  double budgetPercentUsed(double budgetAmount, double spent) {
    if (budgetAmount <= 0) {
      return 0;
    }
    return (spent / budgetAmount) * 100;
  }

  double tripRemaining(double tripBudget, double spent) =>
      tripBudget - spent;

  /// Average spend per day. Returns 0 when [days] is 0 rather than
  /// dividing by zero.
  double averageDailyExpense(double total, int days) {
    if (days <= 0) {
      return 0;
    }
    return total / days;
  }

  /// Sums expense amounts per calendar day (time-of-day stripped), used by
  /// the trip day-wise view and the calendar screen.
  Map<DateTime, double> dayWiseBreakdown(List<Expense> expenses) {
    final Map<DateTime, double> result = <DateTime, double>{};
    for (final Expense expense in expenses) {
      final DateTime day = AppDateUtils.startOfDay(expense.date);
      result[day] = (result[day] ?? 0) + expense.amount;
    }
    return result;
  }

  /// Sums expense amounts per category, keyed by the resolved [Category].
  /// Expenses whose `categoryId` has no matching entry in [categoriesById]
  /// are skipped.
  Map<Category, double> categoryBreakdown(
    List<Expense> expenses,
    Map<int, Category> categoriesById,
  ) {
    final Map<Category, double> result = <Category, double>{};
    for (final Expense expense in expenses) {
      final Category? category = categoriesById[expense.categoryId];
      if (category == null) {
        continue;
      }
      result[category] = (result[category] ?? 0) + expense.amount;
    }
    return result;
  }

  /// Total expense for each of the [monthCount] months ending in [anchor]
  /// (inclusive), oldest first. Keys are the first day of each month.
  Map<DateTime, double> monthlyComparison(
    List<Expense> expenses,
    int monthCount, {
    DateTime? anchor,
  }) {
    final DateTime end = anchor ?? DateTime.now();
    final List<DateTime> months = List<DateTime>.generate(
      monthCount,
      (int i) => DateTime(end.year, end.month - (monthCount - 1 - i)),
    );

    final Map<DateTime, double> result = <DateTime, double>{
      for (final DateTime month in months) month: 0,
    };

    for (final Expense expense in expenses) {
      final DateTime monthKey =
          DateTime(expense.date.year, expense.date.month);
      if (result.containsKey(monthKey)) {
        result[monthKey] = result[monthKey]! + expense.amount;
      }
    }
    return result;
  }

  /// Total income for each of the [monthCount] months ending in [anchor]
  /// (inclusive), oldest first. Keys are the first day of each month.
  Map<DateTime, double> monthlyIncomeComparison(
    List<Income> incomes,
    int monthCount, {
    DateTime? anchor,
  }) {
    final DateTime end = anchor ?? DateTime.now();
    final List<DateTime> months = List<DateTime>.generate(
      monthCount,
      (int i) => DateTime(end.year, end.month - (monthCount - 1 - i)),
    );

    final Map<DateTime, double> result = <DateTime, double>{
      for (final DateTime month in months) month: 0,
    };

    for (final Income income in incomes) {
      final DateTime monthKey = DateTime(income.date.year, income.date.month);
      if (result.containsKey(monthKey)) {
        result[monthKey] = result[monthKey]! + income.amount;
      }
    }
    return result;
  }
}
