import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/budget.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';
import '../../application/budget_progress.dart';
import '../widgets/budget_progress_bar.dart';

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({required this.budgetId, super.key});

  final int budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BudgetProgress?> progress =
        ref.watch(budgetProgressProvider(budgetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Detail'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.budgetEditPath(budgetId)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final Budget? current = progress.value?.budget;
              if (current != null) {
                await _confirmDelete(context, ref, current);
              }
            },
          ),
        ],
      ),
      body: progress.when(
        data: (BudgetProgress? data) {
          if (data == null) {
            return const Center(child: Text('Budget not found'));
          }
          return _BudgetDetailBody(progress: data);
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('Delete "${budget.name}"? This cannot be undone.'),
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
    if ((confirmed ?? false) && context.mounted) {
      await ref.read(budgetRepositoryProvider).delete(budget.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

class _BudgetDetailBody extends ConsumerWidget {
  const _BudgetDetailBody({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Budget budget = progress.budget;
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');
    final double ratio = budget.totalAmount <= 0
        ? 0
        : (progress.spent / budget.totalAmount).clamp(0, 1).toDouble();
    final bool overBudget = progress.spent > budget.totalAmount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(budget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${_periodLabel(budget.periodType)} • '
          '${AppDateUtils.formatShort(budget.startDate)} - '
          '${AppDateUtils.formatShort(budget.endDate)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        BudgetProgressBar(ratio: ratio, overBudget: overBudget, minHeight: 10),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('${formatter.format(progress.spent)} spent'),
            Text('of ${formatter.format(budget.totalAmount)}'),
          ],
        ),
        if (overBudget) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            'Over budget by ${formatter.format(progress.spent - budget.totalAmount)}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (progress.categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          Text('By category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final BudgetCategorySpend cs in progress.categories)
            _CategoryProgressTile(spend: cs, formatter: formatter),
        ],
        const SizedBox(height: 24),
        Text('Expenses', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (progress.expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No expenses recorded in this period yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          for (final Expense expense in progress.expenses)
            _ExpenseTile(expense: expense, formatter: formatter),
      ],
    );
  }

  String _periodLabel(BudgetPeriodType type) {
    switch (type) {
      case BudgetPeriodType.weekly:
        return 'Weekly';
      case BudgetPeriodType.monthly:
        return 'Monthly';
      case BudgetPeriodType.custom:
        return 'Custom';
    }
  }
}

class _CategoryProgressTile extends ConsumerWidget {
  const _CategoryProgressTile({required this.spend, required this.formatter});

  final BudgetCategorySpend spend;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Category?> category =
        ref.watch(_categoryByIdProvider(spend.allocation.categoryId));
    final double allocated = spend.allocation.allocatedAmount;
    final double ratio = allocated <= 0 ? 0 : (spend.spent / allocated).clamp(0, 1).toDouble();
    final bool over = spend.spent > allocated;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CategoryIconAvatar(
            iconName: category.value?.icon ?? 'category',
            color: category.value?.color ?? 0xFF757575,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(category.value?.name ?? '—'),
                const SizedBox(height: 4),
                BudgetProgressBar(ratio: ratio, overBudget: over, minHeight: 6),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(spend.spent)} of ${formatter.format(allocated)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.formatter});

  final Expense expense;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(expense.title),
      subtitle: Text(AppDateUtils.formatShort(expense.date)),
      trailing: Text(formatter.format(expense.amount)),
      onTap: () => context.push(Routes.expenseDetailPath(expense.id)),
    );
  }
}

final FutureProviderFamily<Category?, int> _categoryByIdProvider =
    FutureProvider.family<Category?, int>(
  (Ref ref, int id) => ref.watch(categoryRepositoryProvider).getById(id),
);
