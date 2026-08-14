import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/recurring_expense.dart';
import '../../application/recurring_providers.dart';

/// Single recurring expense row (category icon, title, frequency/next-due
/// subtitle, amount, active toggle, edit/delete menu), used by the
/// Recurring Expenses list.
class RecurringListTile extends ConsumerWidget {
  const RecurringListTile({
    required this.recurringExpense,
    required this.formatter,
    super.key,
    this.category,
    this.account,
  });

  final RecurringExpense recurringExpense;
  final Category? category;
  final Account? account;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: recurringExpense.active ? 1 : 0.5,
      child: ListTile(
        leading: CategoryIconAvatar(
          iconName: category?.icon ?? 'category',
          color: category?.color ?? 0xFF757575,
        ),
        title: Text(recurringExpense.title),
        subtitle: Text(
          <String>[
            recurringFrequencyLabel(recurringExpense.frequency),
            'Next: ${AppDateUtils.formatShort(recurringExpense.nextDate)}',
            account?.name ?? 'Unknown account',
          ].join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              formatter.format(recurringExpense.amount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            PopupMenuButton<String>(
              onSelected: (String action) async {
                if (action == 'edit') {
                  context.push(Routes.recurringAdd, extra: recurringExpense.id);
                } else if (action == 'toggle') {
                  await toggleRecurringActive(
                    ref.read(recurringRepositoryProvider),
                    recurringExpense,
                  );
                } else if (action == 'delete') {
                  await _confirmDelete(context, ref);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: Text(recurringExpense.active ? 'Pause' : 'Resume'),
                ),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete recurring expense?'),
        content: Text(
          'Delete "${recurringExpense.title}"? This cannot be undone.',
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
      await ref.read(recurringRepositoryProvider).delete(recurringExpense.id);
    }
  }
}
