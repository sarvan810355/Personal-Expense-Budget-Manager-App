import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: const EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        message: 'Tap the + button to add your first expense.',
      ),
    );
  }
}
