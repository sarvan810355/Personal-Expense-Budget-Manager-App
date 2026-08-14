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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Expense>> expenses = ref.watch(_expensesProvider);
    final AsyncValue<List<Category>> categories = ref.watch(_categoriesProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Search expenses by name, category, amount, note...',
          ),
          onChanged: (String v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        actions: <Widget>[
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: expenses.when(
        data: (List<Expense> allExpenses) {
          if (_query.isEmpty) {
            return const EmptyStateView(
              icon: Icons.search,
              title: 'Search your expenses',
              message: 'Search by title, category, note, payment method, amount, or date.',
            );
          }

          final Map<int, Category> categoriesById = <int, Category>{
            for (final Category c in categories.value ?? const <Category>[]) c.id: c,
          };
          final CurrencyFormatter formatter =
              CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

          final List<Expense> results = allExpenses.where((Expense e) {
            final String categoryName = categoriesById[e.categoryId]?.name.toLowerCase() ?? '';
            final List<String> haystack = <String>[
              e.title.toLowerCase(),
              categoryName,
              e.note?.toLowerCase() ?? '',
              e.paymentMethod?.toLowerCase() ?? '',
              e.location?.toLowerCase() ?? '',
              e.amount.toString(),
              AppDateUtils.formatShort(e.date).toLowerCase(),
            ];
            return haystack.any((String field) => field.contains(_query));
          }).toList();

          if (results.isEmpty) {
            return EmptyStateView(
              icon: Icons.search_off,
              title: 'No results for "$_query"',
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (BuildContext context, int index) {
              final Expense expense = results[index];
              return ListTile(
                leading: CategoryIconAvatar(
                  iconName: categoriesById[expense.categoryId]?.icon ?? 'category',
                  color: categoriesById[expense.categoryId]?.color ?? 0xFF757575,
                ),
                title: Text(expense.title),
                subtitle: Text(
                  '${categoriesById[expense.categoryId]?.name ?? 'Uncategorized'} • ${AppDateUtils.formatShort(expense.date)}',
                ),
                trailing: Text(formatter.format(expense.amount)),
                onTap: () => context.push(Routes.expenseDetailPath(expense.id)),
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
