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
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/budget.dart';
import '../../application/budget_progress.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Budget>> budgets = ref.watch(_budgetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.budgetCreate),
        child: const Icon(Icons.add),
      ),
      body: budgets.when(
        data: (List<Budget> data) {
          if (data.isEmpty) {
            return const EmptyStateView(
              icon: Icons.pie_chart_outline,
              title: 'No budgets yet',
              message: 'Create a budget to start tracking category spend limits.',
            );
          }
          final List<Budget> sorted = <Budget>[...data]
            ..sort((Budget a, Budget b) => b.startDate.compareTo(a.startDate));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (BuildContext context, int index) =>
                _BudgetCard(budget: sorted[index]),
          );
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BudgetProgress?> progress =
        ref.watch(budgetProgressProvider(budget.id));
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

    final double spent = progress.value?.spent ?? 0;
    final double ratio = budget.totalAmount <= 0
        ? 0
        : (spent / budget.totalAmount).clamp(0, 1).toDouble();
    final bool overBudget = spent > budget.totalAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(Routes.budgetDetailPath(budget.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      budget.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(_periodLabel(budget.periodType)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${AppDateUtils.formatDay(budget.startDate)} - '
                '${AppDateUtils.formatDay(budget.endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  color: overBudget ? Theme.of(context).colorScheme.error : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('${formatter.format(spent)} spent'),
                  Text('of ${formatter.format(budget.totalAmount)}'),
                ],
              ),
            ],
          ),
        ),
      ),
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

final StreamProvider<List<Budget>> _budgetsProvider =
    StreamProvider<List<Budget>>(
  (Ref ref) => ref.watch(budgetRepositoryProvider).watchAll(),
);
