import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/income.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = AppDateUtils.startOfMonth(DateTime.now());
  late DateTime _selectedDay = AppDateUtils.startOfDay(DateTime.now());

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Expense>> expenses = ref.watch(_expensesProvider);
    final AsyncValue<List<Income>> incomes = ref.watch(_incomesProvider);
    final AsyncValue<List<Category>> categories = ref.watch(_categoriesProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: expenses.when(
        data: (List<Expense> allExpenses) {
          final List<Income> allIncomes = incomes.value ?? const <Income>[];
          final Map<DateTime, double> expenseByDay =
              ref.read(calculationServiceProvider).dayWiseBreakdown(allExpenses);
          final Map<DateTime, double> incomeByDay = <DateTime, double>{};
          for (final Income income in allIncomes) {
            final DateTime day = AppDateUtils.startOfDay(income.date);
            incomeByDay[day] = (incomeByDay[day] ?? 0) + income.amount;
          }

          final CurrencyFormatter formatter =
              CurrencyFormatter(settings.value?.currencyCode ?? 'INR');
          final Map<int, Category> categoriesById = <int, Category>{
            for (final Category c in categories.value ?? const <Category>[]) c.id: c,
          };
          final List<Expense> selectedDayExpenses = allExpenses
              .where((Expense e) => AppDateUtils.isSameDay(e.date, _selectedDay))
              .toList();

          return Column(
            children: <Widget>[
              _MonthHeader(month: _month, onChange: _changeMonth),
              _MonthGrid(
                month: _month,
                selectedDay: _selectedDay,
                expenseByDay: expenseByDay,
                incomeByDay: incomeByDay,
                onSelect: (DateTime day) => setState(() => _selectedDay = day),
              ),
              const Divider(height: 1),
              Expanded(
                child: _DaySummary(
                  day: _selectedDay,
                  expenses: selectedDayExpenses,
                  totalIncome: incomeByDay[_selectedDay] ?? 0,
                  totalExpense: expenseByDay[_selectedDay] ?? 0,
                  categoriesById: categoriesById,
                  formatter: formatter,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onChange});

  final DateTime month;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChange(-1),
          ),
          Text(AppDateUtils.formatMonthYear(month), style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChange(1),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.expenseByDay,
    required this.incomeByDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, double> expenseByDay;
  final Map<DateTime, double> incomeByDay;
  final ValueChanged<DateTime> onSelect;

  static const List<String> _weekdayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final DateTime firstOfMonth = DateTime(month.year, month.month);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int leadingBlanks = firstOfMonth.weekday - 1;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final String label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (BuildContext context, int index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }
              final DateTime day = DateTime(month.year, month.month, index - leadingBlanks + 1);
              final bool hasExpense = (expenseByDay[day] ?? 0) > 0;
              final bool hasIncome = (incomeByDay[day] ?? 0) > 0;
              final bool selected = AppDateUtils.isSameDay(day, selectedDay);

              return InkWell(
                onTap: () => onSelect(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primaryContainer : null,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('${day.day}', style: Theme.of(context).textTheme.bodyMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (hasExpense) _Dot(color: scheme.error),
                          if (hasIncome) _Dot(color: scheme.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.day,
    required this.expenses,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoriesById,
    required this.formatter,
  });

  final DateTime day;
  final List<Expense> expenses;
  final double totalIncome;
  final double totalExpense;
  final Map<int, Category> categoriesById;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(AppDateUtils.formatShort(day), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryStat(label: 'Income', value: formatter.format(totalIncome)),
            ),
            Expanded(
              child: _SummaryStat(label: 'Expense', value: formatter.format(totalExpense)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
          const EmptyStateView(icon: Icons.event_busy_outlined, title: 'No expenses on this day')
        else
          for (final Expense expense in expenses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CategoryIconAvatar(
                iconName: categoriesById[expense.categoryId]?.icon ?? 'category',
                color: categoriesById[expense.categoryId]?.color ?? 0xFF757575,
              ),
              title: Text(expense.title),
              subtitle: Text(categoriesById[expense.categoryId]?.name ?? 'Uncategorized'),
              trailing: Text(formatter.format(expense.amount)),
              onTap: () => context.push(Routes.expenseDetailPath(expense.id)),
            ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

final StreamProvider<List<Expense>> _expensesProvider =
    StreamProvider<List<Expense>>(
  (Ref ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);

final StreamProvider<List<Income>> _incomesProvider =
    StreamProvider<List<Income>>(
  (Ref ref) => ref.watch(incomeRepositoryProvider).watchAll(),
);

final StreamProvider<List<Category>> _categoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);
