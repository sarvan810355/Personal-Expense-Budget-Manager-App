import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/income.dart';
import '../../application/income_providers.dart';
import '../widgets/income_list_tile.dart';

class IncomeListScreen extends ConsumerWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<IncomeMonthGroup>> groups =
        ref.watch(incomeMonthGroupsProvider);
    final AsyncValue<List<Category>> categories =
        ref.watch(incomeCategoriesProvider);
    final AsyncValue<List<Account>> accounts =
        ref.watch(incomeAccountsProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.addIncome),
        child: const Icon(Icons.add),
      ),
      body: groups.when(
        data: (List<IncomeMonthGroup> data) {
          if (data.isEmpty) {
            return const EmptyStateView(
              icon: Icons.attach_money_outlined,
              title: 'No income recorded yet',
              message: 'Tap the + button to add your first income entry.',
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

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: data.length,
            itemBuilder: (BuildContext context, int index) {
              final IncomeMonthGroup group = data[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          AppDateUtils.formatMonthYear(group.month),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          formatter.format(group.total),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  for (final Income income in group.entries)
                    IncomeListTile(
                      income: income,
                      category: income.categoryId == null ? null : categoriesById[income.categoryId],
                      account: accountsById[income.accountId],
                      formatter: formatter,
                    ),
                ],
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
