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
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final int expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Expense?> expense =
        ref.watch(_expenseByIdProvider(expenseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Detail'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.addExpense, extra: expenseId),
          ),
          PopupMenuButton<String>(
            onSelected: (String action) async {
              final Expense? current = expense.value;
              if (current == null) {
                return;
              }
              if (action == 'duplicate') {
                await _duplicate(context, ref, current);
              } else if (action == 'delete') {
                await _confirmDelete(context, ref, current);
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: expense.when(
        data: (Expense? data) {
          if (data == null) {
            return const Center(child: Text('Expense not found'));
          }
          return _ExpenseDetailBody(expense: data);
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref, Expense expense) async {
    final DateTime now = DateTime.now();
    await ref.read(expenseRepositoryProvider).create(
          expense.copyWith(id: 0, date: now, createdAt: now, updatedAt: now),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense duplicated')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Expense expense) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete "${expense.title}"? This cannot be undone.'),
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
      await ref.read(expenseRepositoryProvider).delete(expense.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

class _ExpenseDetailBody extends ConsumerWidget {
  const _ExpenseDetailBody({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Category?> category =
        ref.watch(_categoryByIdProvider(expense.categoryId));
    final AsyncValue<Account?> account =
        ref.watch(_accountByIdProvider(expense.accountId));
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              CategoryIconAvatar(
                iconName: category.value?.icon ?? 'category',
                color: category.value?.color ?? 0xFF757575,
                radius: 32,
              ),
              const SizedBox(height: 12),
              Text(
                formatter.format(expense.amount),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(expense.title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DetailRow(label: 'Category', value: category.value?.name ?? '—'),
        _DetailRow(label: 'Account', value: account.value?.name ?? '—'),
        _DetailRow(
          label: 'Date',
          value: AppDateUtils.formatShort(expense.date) + (expense.time != null ? ' • ${expense.time}' : ''),
        ),
        if (expense.paymentMethod != null)
          _DetailRow(label: 'Payment method', value: expense.paymentMethod!),
        if (expense.location != null) _DetailRow(label: 'Location', value: expense.location!),
        if (expense.note != null) _DetailRow(label: 'Note', value: expense.note!),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

final FutureProviderFamily<Expense?, int> _expenseByIdProvider =
    FutureProvider.family<Expense?, int>(
  (Ref ref, int id) => ref.watch(expenseRepositoryProvider).getById(id),
);

final FutureProviderFamily<Category?, int> _categoryByIdProvider =
    FutureProvider.family<Category?, int>(
  (Ref ref, int id) => ref.watch(categoryRepositoryProvider).getById(id),
);

final FutureProviderFamily<Account?, int> _accountByIdProvider =
    FutureProvider.family<Account?, int>(
  (Ref ref, int id) => ref.watch(accountRepositoryProvider).getById(id),
);
