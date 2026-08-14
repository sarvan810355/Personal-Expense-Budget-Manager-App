import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({required this.budgetId, super.key});

  final int budgetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Budget #$budgetId')),
      body: const EmptyStateView(
        icon: Icons.pie_chart_outline,
        title: 'Budget detail coming in Phase 4',
      ),
    );
  }
}
