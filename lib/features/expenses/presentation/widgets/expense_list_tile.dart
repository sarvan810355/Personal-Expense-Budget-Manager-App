import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';

/// Single expense row (category icon, title, category/payment subtitle,
/// amount), used by the Expense List and the Dashboard's recent
/// transactions list.
class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    required this.expense,
    required this.formatter,
    super.key,
    this.category,
  });

  final Expense expense;
  final Category? category;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CategoryIconAvatar(
        iconName: category?.icon ?? 'category',
        color: category?.color ?? 0xFF757575,
      ),
      title: Text(expense.title),
      subtitle: Text(
        <String>[
          category?.name ?? 'Uncategorized',
          if (expense.paymentMethod != null) expense.paymentMethod!,
        ].join(' • '),
      ),
      trailing: Text(
        formatter.format(expense.amount),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () => context.push(Routes.expenseDetailPath(expense.id)),
    );
  }
}
