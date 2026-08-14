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
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/trip.dart';
import '../../../budgets/presentation/widgets/budget_progress_bar.dart';
import '../../../expenses/presentation/widgets/expense_list_tile.dart';
import '../../application/trip_providers.dart';
import '../widgets/trip_category_budget_tile.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TripProgress?> progress = ref.watch(tripProgressProvider(tripId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(progress.value?.trip.name ?? 'Trip #$tripId'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.tripCreate, extra: tripId),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final Trip? current = progress.value?.trip;
                if (current != null) {
                  await _confirmDelete(context, ref, current);
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Overview'),
              Tab(text: 'Expenses'),
              Tab(text: 'Day-wise'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(Routes.tripAddExpensePath(tripId)),
          child: const Icon(Icons.add),
        ),
        body: progress.when(
          data: (TripProgress? data) {
            if (data == null) {
              return const Center(child: Text('Trip not found'));
            }
            return TabBarView(
              children: <Widget>[
                _OverviewTab(progress: data),
                _ExpensesTab(progress: data),
                _DayWiseTab(tripId: tripId),
              ],
            );
          },
          loading: () => const LoadingView(),
          error: (Object e, StackTrace st) => ErrorView(message: '$e'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Trip trip) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('Delete "${trip.name}"? This cannot be undone.'),
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
      await ref.read(tripRepositoryProvider).delete(trip.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.progress});

  final TripProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Trip trip = progress.trip;
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');
    final double ratio = trip.totalBudget <= 0
        ? 0
        : (progress.spent / trip.totalBudget).clamp(0, 1).toDouble();
    final bool overBudget = progress.spent > trip.totalBudget;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(trip.destination, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${AppDateUtils.formatShort(trip.startDate)} - '
          '${AppDateUtils.formatShort(trip.endDate)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (trip.notes != null && trip.notes!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(trip.notes!),
        ],
        const SizedBox(height: 16),
        BudgetProgressBar(ratio: ratio, overBudget: overBudget, minHeight: 10),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('${formatter.format(progress.spent)} spent'),
            Text('of ${formatter.format(trip.totalBudget)}'),
          ],
        ),
        if (overBudget) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            'Over budget by ${formatter.format(progress.spent - trip.totalBudget)}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        Text('By category', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (progress.categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No category budgets set for this trip yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          for (final TripCategorySpend cs in progress.categories)
            TripCategoryBudgetTile(spend: cs, formatter: formatter),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.progress});

  final TripProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress.expenses.isEmpty) {
      return const EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        message: 'Tap the + button to log an expense for this trip.',
      );
    }

    final AsyncValue<List<Category>> categories = ref.watch(tripExpenseCategoriesProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');
    final Map<int, Category> categoriesById = <int, Category>{
      for (final Category c in categories.value ?? const <Category>[]) c.id: c,
    };

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: progress.expenses.length,
      itemBuilder: (BuildContext context, int index) {
        final Expense expense = progress.expenses[index];
        return ExpenseListTile(
          expense: expense,
          category: categoriesById[expense.categoryId],
          formatter: formatter,
        );
      },
    );
  }
}

class _DayWiseTab extends ConsumerWidget {
  const _DayWiseTab({required this.tripId});

  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TripDayGroup>> dayGroups = ref.watch(tripDayGroupsProvider(tripId));
    final AsyncValue<List<Category>> categories = ref.watch(tripExpenseCategoriesProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');
    final Map<int, Category> categoriesById = <int, Category>{
      for (final Category c in categories.value ?? const <Category>[]) c.id: c,
    };

    return dayGroups.when(
      data: (List<TripDayGroup> groups) {
        if (groups.isEmpty) {
          return const EmptyStateView(
            icon: Icons.calendar_view_day_outlined,
            title: 'No expenses yet',
            message: 'Expenses will be grouped by day once you log some.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            for (final TripDayGroup group in groups) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    AppDateUtils.formatShort(group.day),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(formatter.format(group.total)),
                ],
              ),
              for (final Expense expense in group.expenses)
                ExpenseListTile(
                  expense: expense,
                  category: categoriesById[expense.categoryId],
                  formatter: formatter,
                ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (Object e, StackTrace st) => ErrorView(message: '$e'),
    );
  }
}
