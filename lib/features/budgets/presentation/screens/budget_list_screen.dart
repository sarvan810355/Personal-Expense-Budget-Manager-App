import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class BudgetListScreen extends StatelessWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: const EmptyStateView(
        icon: Icons.pie_chart_outline,
        title: 'No budgets yet',
        message: 'Create a budget to start tracking category spend limits.',
      ),
    );
  }
}
