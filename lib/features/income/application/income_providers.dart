import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/income.dart';

/// Live list of all income entries, newest first (list state shared by the
/// list screen and the add/edit screen's "existing entry" lookups so both
/// stay in sync after a write).
final StreamProvider<List<Income>> incomesProvider =
    StreamProvider<List<Income>>(
  (Ref ref) => ref.watch(incomeRepositoryProvider).watchAll(),
);

/// One calendar month's income entries plus their combined total.
class IncomeMonthGroup {
  const IncomeMonthGroup({
    required this.month,
    required this.entries,
    required this.total,
  });

  final DateTime month;
  final List<Income> entries;
  final double total;
}

/// [incomesProvider] grouped by month (newest first) so the list screen
/// doesn't recompute totals on every rebuild.
final Provider<AsyncValue<List<IncomeMonthGroup>>> incomeMonthGroupsProvider =
    Provider<AsyncValue<List<IncomeMonthGroup>>>((Ref ref) {
  final AsyncValue<List<Income>> incomes = ref.watch(incomesProvider);
  return incomes.whenData((List<Income> data) {
    final Map<DateTime, List<Income>> grouped = <DateTime, List<Income>>{};
    for (final Income income in data) {
      final DateTime month = DateTime(income.date.year, income.date.month);
      grouped.putIfAbsent(month, () => <Income>[]).add(income);
    }
    final List<DateTime> months = grouped.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return <IncomeMonthGroup>[
      for (final DateTime month in months)
        IncomeMonthGroup(
          month: month,
          entries: grouped[month]!..sort((Income a, Income b) => b.date.compareTo(a.date)),
          total: grouped[month]!.fold(0.0, (double sum, Income i) => sum + i.amount),
        ),
    ];
  });
});

/// Single income entry looked up by id, used to prefill the edit form.
final FutureProviderFamily<Income?, int> incomeByIdProvider =
    FutureProvider.family<Income?, int>(
  (Ref ref, int id) => ref.watch(incomeRepositoryProvider).getById(id),
);

/// Income-type categories offered by the add/edit form's category picker.
final StreamProvider<List<Category>> incomeCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchByType(CategoryType.income),
);

/// Accounts offered by the add/edit form's account picker, and used by the
/// list screen to show which account each income entry was credited to.
final StreamProvider<List<Account>> incomeAccountsProvider =
    StreamProvider<List<Account>>(
  (Ref ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Display label for an [IncomeSource], used when an entry has no category.
String incomeSourceLabel(IncomeSource source) {
  switch (source) {
    case IncomeSource.salary:
      return 'Salary';
    case IncomeSource.business:
      return 'Business';
    case IncomeSource.investment:
      return 'Investment';
    case IncomeSource.freelance:
      return 'Freelance';
    case IncomeSource.gift:
      return 'Gift';
    case IncomeSource.other:
      return 'Other';
  }
}

/// Icon key (see `AppIcons`) for an [IncomeSource], matching the seed icon
/// used by the equivalently-named default income category.
String incomeSourceIcon(IncomeSource source) {
  switch (source) {
    case IncomeSource.salary:
      return 'work';
    case IncomeSource.business:
      return 'store';
    case IncomeSource.investment:
      return 'trending_up';
    case IncomeSource.freelance:
      return 'laptop_mac';
    case IncomeSource.gift:
      return 'redeem';
    case IncomeSource.other:
      return 'attach_money';
  }
}

/// Fallback tint for an income entry with no category, matching the color
/// used by the seeded default income categories.
const int kIncomeColor = 0xFF2E7D32;
