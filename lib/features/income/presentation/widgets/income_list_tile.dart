import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/income.dart';
import '../../application/income_providers.dart';

/// Single income row (category/source icon, category or source label,
/// account/note subtitle, amount, edit/delete menu), used by the Income
/// List and the Dashboard's recent transactions list.
class IncomeListTile extends ConsumerWidget {
  const IncomeListTile({
    required this.income,
    required this.formatter,
    super.key,
    this.category,
    this.account,
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
