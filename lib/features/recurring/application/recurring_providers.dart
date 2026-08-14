import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/recurring_expense.dart';
import '../../../domain/repositories/recurring_repository.dart';

/// Live list of all recurring expenses (list state shared by the list
/// screen and the add/edit screen's "existing entry" lookups so both stay
/// in sync after a write).
final StreamProvider<List<RecurringExpense>> recurringExpensesProvider =
    StreamProvider<List<RecurringExpense>>(
  (Ref ref) => ref.watch(recurringRepositoryProvider).watchAll(),
);

/// Single recurring expense looked up by id, used to prefill the edit form.
final FutureProviderFamily<RecurringExpense?, int> recurringByIdProvider =
    FutureProvider.family<RecurringExpense?, int>(
  (Ref ref, int id) => ref.watch(recurringRepositoryProvider).getById(id),
);

/// Expense-type categories offered by the add/edit form's category picker.
final StreamProvider<List<Category>> recurringCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchByType(CategoryType.expense),
);

/// Accounts offered by the add/edit form's account picker, and used by the
/// list screen to show which account each recurring expense is charged to.
final StreamProvider<List<Account>> recurringAccountsProvider =
    StreamProvider<List<Account>>(
  (Ref ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Display label for a [RecurringFrequency].
String recurringFrequencyLabel(RecurringFrequency frequency) {
  switch (frequency) {
    case RecurringFrequency.daily:
      return 'Daily';
    case RecurringFrequency.weekly:
      return 'Weekly';
    case RecurringFrequency.monthly:
      return 'Monthly';
    case RecurringFrequency.yearly:
      return 'Yearly';
  }
}

/// Flips [RecurringExpense.active] and persists the change, used by the
/// list screen's pause/resume action.
Future<void> toggleRecurringActive(
  RecurringRepository repository,
  RecurringExpense recurringExpense,
) {
  return repository.update(recurringExpense.copyWith(active: !recurringExpense.active));
}
