import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final int expenseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expense #$expenseId')),
      body: const EmptyStateView(
        icon: Icons.receipt_outlined,
        title: 'Expense detail coming in Phase 2',
      ),
    );
  }
}
