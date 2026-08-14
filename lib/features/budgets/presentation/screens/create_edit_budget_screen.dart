import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class CreateEditBudgetScreen extends StatelessWidget {
  const CreateEditBudgetScreen({super.key, this.budgetId});

  final int? budgetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(budgetId == null ? 'Create Budget' : 'Edit Budget')),
      body: const EmptyStateView(
        icon: Icons.add_chart_outlined,
        title: 'Budget form coming in Phase 4',
      ),
    );
  }
}
