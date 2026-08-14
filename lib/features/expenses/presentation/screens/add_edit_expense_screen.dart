import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AddEditExpenseScreen extends StatelessWidget {
  const AddEditExpenseScreen({super.key, this.expenseId});

  final int? expenseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(expenseId == null ? 'Add Expense' : 'Edit Expense')),
      body: const EmptyStateView(
        icon: Icons.edit_outlined,
        title: 'Expense form coming in Phase 2',
      ),
    );
  }
}
