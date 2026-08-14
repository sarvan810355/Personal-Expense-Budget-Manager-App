import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/entities/trip_category_budget.dart';

/// Live list of all trips (list state shared by the list screen and the
/// create/edit screen's "existing entry" lookups so both stay in sync).
final StreamProvider<List<Trip>> tripsProvider = StreamProvider<List<Trip>>(
  (Ref ref) => ref.watch(tripRepositoryProvider).watchAll(),
);

/// Single trip looked up by id, used to prefill the edit form and the
/// detail screen's app bar.
final FutureProviderFamily<Trip?, int> tripByIdProvider =
    FutureProvider.family<Trip?, int>(
  (Ref ref, int id) => ref.watch(tripRepositoryProvider).getById(id),
);

/// A trip's category budget allocations, used to prefill the edit form.
final FutureProviderFamily<List<TripCategoryBudget>, int>
    tripCategoryBudgetsProvider = FutureProvider.family<List<TripCategoryBudget>, int>(
  (Ref ref, int tripId) =>
      ref.watch(tripRepositoryProvider).watchCategoryBudgetsForTrip(tripId).first,
);

/// Expense-type categories offered by the trip form's category allocation
/// rows and the add-trip-expense form's category picker.
final StreamProvider<List<Category>> tripExpenseCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchByType(CategoryType.expense),
);

/// Accounts offered by the add-trip-expense form's account picker.
final StreamProvider<List<Account>> tripAccountsProvider =
    StreamProvider<List<Account>>(
  (Ref ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Spend for a single category allocation within a trip.
class TripCategorySpend {
  const TripCategorySpend({required this.allocation, required this.spent});

  final TripCategoryBudget allocation;
  final double spent;
}

/// Aggregated view of a trip: total spent against [Trip.totalBudget],
/// per-category spend against each [TripCategoryBudget] allocation, and the
/// expenses (newest first) tied to the trip.
class TripProgress {
  const TripProgress({
    required this.trip,
    required this.spent,
    required this.categories,
    required this.expenses,
  });

  final Trip trip;
  final double spent;
  final List<TripCategorySpend> categories;
  final List<Expense> expenses;
}

/// Loads a trip's category budgets and the expenses tied to it, then sums
/// spend overall and per allocated category.
final FutureProviderFamily<TripProgress?, int> tripProgressProvider =
    FutureProvider.family<TripProgress?, int>((Ref ref, int tripId) async {
  final Trip? trip = await ref.watch(tripRepositoryProvider).getById(tripId);
  if (trip == null) {
    return null;
  }

  final List<TripCategoryBudget> allocations = await ref
      .watch(tripRepositoryProvider)
      .watchCategoryBudgetsForTrip(tripId)
      .first;
  final List<Expense> expenses =
      await ref.watch(expenseRepositoryProvider).watchByTrip(tripId).first;

  final List<Expense> sorted = <Expense>[...expenses]
    ..sort((Expense a, Expense b) => b.date.compareTo(a.date));

  final double totalSpent =
      expenses.fold<double>(0, (double sum, Expense e) => sum + e.amount);

  final List<TripCategorySpend> categorySpend = <TripCategorySpend>[
    for (final TripCategoryBudget allocation in allocations)
      TripCategorySpend(
        allocation: allocation,
        spent: expenses
            .where((Expense e) => e.categoryId == allocation.categoryId)
            .fold<double>(0, (double sum, Expense e) => sum + e.amount),
      ),
  ];

  return TripProgress(
    trip: trip,
    spent: totalSpent,
    categories: categorySpend,
    expenses: sorted,
  );
});

/// One calendar day's trip expenses plus their combined total.
class TripDayGroup {
  const TripDayGroup({required this.day, required this.expenses, required this.total});

  final DateTime day;
  final List<Expense> expenses;
  final double total;
}

/// [tripProgressProvider]'s expenses grouped by day (newest first), used by
/// the trip detail screen's day-wise tab.
final ProviderFamily<AsyncValue<List<TripDayGroup>>, int> tripDayGroupsProvider =
    Provider.family<AsyncValue<List<TripDayGroup>>, int>((Ref ref, int tripId) {
  final AsyncValue<TripProgress?> progress = ref.watch(tripProgressProvider(tripId));
  return progress.whenData((TripProgress? data) {
    if (data == null) {
      return const <TripDayGroup>[];
    }
    final Map<DateTime, List<Expense>> grouped = <DateTime, List<Expense>>{};
    for (final Expense expense in data.expenses) {
      final DateTime day = AppDateUtils.startOfDay(expense.date);
      grouped.putIfAbsent(day, () => <Expense>[]).add(expense);
    }
    final List<DateTime> days = grouped.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return <TripDayGroup>[
      for (final DateTime day in days)
        TripDayGroup(
          day: day,
          expenses: grouped[day]!,
          total: grouped[day]!.fold(0.0, (double sum, Expense e) => sum + e.amount),
        ),
    ];
  });
});
