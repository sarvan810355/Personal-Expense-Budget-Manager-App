import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/budget.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/income.dart';
import '../../../budgets/application/budget_progress.dart';
import '../../../budgets/presentation/widgets/budget_progress_bar.dart';
import '../../../expenses/presentation/widgets/expense_list_tile.dart';
import '../../../income/application/income_providers.dart';
import '../../../income/presentation/widgets/income_list_tile.dart';
import '../../application/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Expense>> allExpenses = ref.watch(allExpensesProvider);
    final AsyncValue<List<Income>> allIncomes = ref.watch(incomesProvider);
    final AsyncValue<List<Budget>> allBudgets = ref.watch(allBudgetsProvider);

    if (allExpenses.isLoading || allIncomes.isLoading || allBudgets.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const LoadingView(),
      );
    }

    final Object? error = allExpenses.error ?? allIncomes.error ?? allBudgets.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: ErrorView(message: '$error'),
      );
    }

    final bool hasNoData = (allExpenses.value ?? const <Expense>[]).isEmpty &&
        (allIncomes.value ?? const <Income>[]).isEmpty &&
        (allBudgets.value ?? const <Budget>[]).isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: hasNoData
          ? const EmptyStateView(
              icon: Icons.dashboard_outlined,
              title: 'Your dashboard is empty',
              message: 'Once you add expenses and income, your summary will show up here.',
            )
          : const _DashboardBody(),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SummaryCard(formatter: formatter),
        const SectionHeader(title: 'Budgets'),
        _BudgetProgressSection(formatter: formatter),
        const SectionHeader(title: 'Spending by category'),
        _CategoryBreakdownSection(formatter: formatter),
        const SectionHeader(title: 'Recent transactions'),
        _RecentTransactionsSection(formatter: formatter),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.formatter});

  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MonthlySummary> summary = ref.watch(monthlySummaryProvider);

    return summary.when(
      data: (MonthlySummary data) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'This month',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryFigure(
                      label: 'Income',
                      value: formatter.format(data.totalIncome),
                      color: scheme.tertiary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryFigure(
                      label: 'Expenses',
                      value: formatter.format(data.totalExpense),
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _SummaryFigure(
                label: 'Net balance',
                value: formatter.format(data.net),
                color: data.net < 0 ? scheme.error : scheme.tertiary,
              ),
            ],
          ),
        );
      },
      loading: () => const AppCard(child: LoadingView()),
      error: (Object e, StackTrace st) => AppCard(child: ErrorView(message: '$e')),
    );
  }
}

class _SummaryFigure extends StatelessWidget {
  const _SummaryFigure({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _BudgetProgressSection extends ConsumerWidget {
  const _BudgetProgressSection({required this.formatter});

  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BudgetProgress>> progress =
        ref.watch(dashboardBudgetProgressProvider);

    return progress.when(
      data: (List<BudgetProgress> data) {
        if (data.isEmpty) {
          return const AppCard(
            child: Text('No budgets yet. Create one from the Budgets tab.'),
          );
        }
        return Column(
          children: <Widget>[
            for (final BudgetProgress p in data)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetProgressCard(progress: p, formatter: formatter),
              ),
          ],
        );
      },
      loading: () => const AppCard(child: LoadingView()),
      error: (Object e, StackTrace st) => AppCard(child: ErrorView(message: '$e')),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({required this.progress, required this.formatter});

  final BudgetProgress progress;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final Budget budget = progress.budget;
    final double ratio = budget.totalAmount <= 0
        ? 0
        : (progress.spent / budget.totalAmount).clamp(0, 1).toDouble();
    final bool overBudget = progress.spent > budget.totalAmount;

    return AppCard(
      onTap: () => context.push(Routes.budgetDetailPath(budget.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(budget.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          BudgetProgressBar(ratio: ratio, overBudget: overBudget),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('${formatter.format(progress.spent)} spent'),
              Text('of ${formatter.format(budget.totalAmount)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownSection extends ConsumerWidget {
  const _CategoryBreakdownSection({required this.formatter});

  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CategorySpend>> breakdown =
        ref.watch(currentMonthCategoryBreakdownProvider);

    return breakdown.when(
      data: (List<CategorySpend> data) {
        if (data.isEmpty) {
          return const AppCard(
            child: Text('No expenses recorded this month yet.'),
          );
        }
        return AppCard(
          child: Column(
            children: <Widget>[
              for (final CategorySpend spend in data)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(child: Text(spend.category.name)),
                      Text(formatter.format(spend.amount)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const AppCard(child: LoadingView()),
      error: (Object e, StackTrace st) => AppCard(child: ErrorView(message: '$e')),
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection({required this.formatter});

  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecentTransaction>> transactions =
        ref.watch(recentTransactionsProvider);
    final AsyncValue<List<Category>> categories = ref.watch(allCategoriesProvider);
    final AsyncValue<List<Account>> accounts = ref.watch(allAccountsProvider);

    return transactions.when(
      data: (List<RecentTransaction> data) {
        if (data.isEmpty) {
          return const AppCard(child: Text('No transactions recorded yet.'));
        }
        final Map<int, Category> categoriesById = <int, Category>{
          for (final Category c in categories.value ?? const <Category>[]) c.id: c,
        };
        final Map<int, Account> accountsById = <int, Account>{
          for (final Account a in accounts.value ?? const <Account>[]) a.id: a,
        };
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (final RecentTransaction t in data)
                if (t.expense != null)
                  ExpenseListTile(
                    expense: t.expense!,
                    category: categoriesById[t.expense!.categoryId],
                    formatter: formatter,
                  )
                else if (t.income != null)
                  IncomeListTile(
                    income: t.income!,
                    category: t.income!.categoryId == null
                        ? null
                        : categoriesById[t.income!.categoryId],
                    account: accountsById[t.income!.accountId],
                    formatter: formatter,
                  ),
            ],
          ),
        );
      },
      loading: () => const AppCard(child: LoadingView()),
      error: (Object e, StackTrace st) => AppCard(child: ErrorView(message: '$e')),
    );
  }
}
