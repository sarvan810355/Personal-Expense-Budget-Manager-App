import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/recurring_expense.dart';
import '../../application/recurring_providers.dart';
import '../widgets/recurring_list_tile.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecurringExpense>> recurringExpenses =
        ref.watch(recurringExpensesProvider);
    final AsyncValue<List<Category>> categories =
        ref.watch(recurringCategoriesProvider);
    final AsyncValue<List<Account>> accounts =
        ref.watch(recurringAccountsProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.recurringAdd),
        child: const Icon(Icons.add),
      ),
      body: recurringExpenses.when(
        data: (List<RecurringExpense> data) {
          if (data.isEmpty) {
            return const EmptyStateView(
              icon: Icons.autorenew_outlined,
              title: 'No recurring expenses yet',
              message: 'Tap the + button to set up your first recurring expense.',
            );
          }

          final Map<int, Category> categoriesById = <int, Category>{
            for (final Category c in categories.value ?? const <Category>[]) c.id: c,
          };
          final Map<int, Account> accountsById = <int, Account>{
            for (final Account a in accounts.value ?? const <Account>[]) a.id: a,
          };
          final CurrencyFormatter formatter =
              CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

          final List<RecurringExpense> sorted = <RecurringExpense>[...data]..sort(
              (RecurringExpense a, RecurringExpense b) {
                if (a.active != b.active) {
                  return a.active ? -1 : 1;
                }
                return a.nextDate.compareTo(b.nextDate);
              },
            );

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: sorted.length,
            itemBuilder: (BuildContext context, int index) {
              final RecurringExpense recurringExpense = sorted[index];
              return RecurringListTile(
                recurringExpense: recurringExpense,
                category: categoriesById[recurringExpense.categoryId],
                account: accountsById[recurringExpense.accountId],
                formatter: formatter,
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }
}
