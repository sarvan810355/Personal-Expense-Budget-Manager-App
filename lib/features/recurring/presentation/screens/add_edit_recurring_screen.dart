import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AddEditRecurringScreen extends StatelessWidget {
  const AddEditRecurringScreen({super.key, this.recurringId});

  final int? recurringId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recurringId == null ? 'Add Recurring Expense' : 'Edit Recurring Expense')),
      body: const EmptyStateView(
        icon: Icons.edit_outlined,
        title: 'Recurring expense form coming in Phase 7',
      ),
    );
  }
}
