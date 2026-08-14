import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/income.dart';
import '../../application/income_providers.dart';

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
                    _IncomeTile(
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

class _IncomeTile extends ConsumerWidget {
  const _IncomeTile({
    required this.income,
    required this.category,
    required this.account,
    required this.formatter,
  });

  final Income income;
  final Category? category;
  final Account? account;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CategoryIconAvatar(
        iconName: category?.icon ?? incomeSourceIcon(income.source),
        color: category?.color ?? kIncomeColor,
      ),
      title: Text(category?.name ?? incomeSourceLabel(income.source)),
      subtitle: Text(
        <String>[
          account?.name ?? 'Unknown account',
          if (income.note != null && income.note!.isNotEmpty) income.note!,
        ].join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '+${formatter.format(income.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          PopupMenuButton<String>(
            onSelected: (String action) async {
              if (action == 'edit') {
                context.push(Routes.addIncome, extra: income.id);
              } else if (action == 'delete') {
                await _confirmDelete(context, ref);
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete income?'),
        content: Text(
          'Delete this ${formatter.format(income.amount)} entry? This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(incomeRepositoryProvider).delete(income.id);
    }
  }
}
