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
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';
import '../../application/expense_filter.dart';
import '../widgets/expense_filter_sheet.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  ExpenseFilter _filter = const ExpenseFilter();

  Future<void> _openFilters() async {
    final ExpenseFilter? result = await showModalBottomSheet<ExpenseFilter>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => ExpenseFilterSheet(initial: _filter),
    );
    if (result != null) {
      setState(() => _filter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Expense>> expenses = ref.watch(_expensesProvider);
    final AsyncValue<List<Category>> categories =
        ref.watch(_categoriesProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.search),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _filter.isEmpty ? null : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: expenses.when(
        data: (List<Expense> allExpenses) {
          final List<Expense> filtered = _filter.apply(allExpenses);
          if (filtered.isEmpty) {
            return EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: allExpenses.isEmpty ? 'No expenses yet' : 'No expenses match your filters',
              message: allExpenses.isEmpty
                  ? 'Tap the + button to add your first expense.'
                  : 'Try clearing or adjusting the filters.',
            );
          }

          final Map<int, Category> categoriesById = <int, Category>{
            for (final Category c in categories.value ?? const <Category>[]) c.id: c,
          };
          final CurrencyFormatter formatter =
              CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

          final Map<DateTime, List<Expense>> grouped = <DateTime, List<Expense>>{};
          for (final Expense e in filtered) {
            final DateTime day = AppDateUtils.startOfDay(e.date);
            grouped.putIfAbsent(day, () => <Expense>[]).add(e);
          }
          final List<DateTime> days = grouped.keys.toList()
            ..sort((DateTime a, DateTime b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: days.length,
            itemBuilder: (BuildContext context, int index) {
              final DateTime day = days[index];
              final List<Expense> dayExpenses = grouped[day]!;
              final double dayTotal =
                  dayExpenses.fold(0, (double sum, Expense e) => sum + e.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          AppDateUtils.formatShort(day),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          formatter.format(dayTotal),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  for (final Expense expense in dayExpenses)
                    ListTile(
                      leading: CategoryIconAvatar(
                        iconName: categoriesById[expense.categoryId]?.icon ?? 'category',
                        color: categoriesById[expense.categoryId]?.color ?? 0xFF757575,
                      ),
                      title: Text(expense.title),
                      subtitle: Text(
                        <String>[
                          categoriesById[expense.categoryId]?.name ?? 'Uncategorized',
                          if (expense.paymentMethod != null) expense.paymentMethod!,
                        ].join(' • '),
                      ),
                      trailing: Text(
                        formatter.format(expense.amount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: () => context.push(Routes.expenseDetailPath(expense.id)),
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

final StreamProvider<List<Expense>> _expensesProvider =
    StreamProvider<List<Expense>>(
  (Ref ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);

final StreamProvider<List<Category>> _categoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);
