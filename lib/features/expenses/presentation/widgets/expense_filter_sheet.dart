import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

/// Bottom sheet for filtering the Expense List (category, account, date
/// range, tags). Presented via `showModalBottomSheet`, not a go_router
/// route. Real filter controls land in Phase 2.
class ExpenseFilterSheet extends StatelessWidget {
  const ExpenseFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: EmptyStateView(
        icon: Icons.filter_list,
        title: 'Filters coming in Phase 2',
      ),
    );
  }
}
