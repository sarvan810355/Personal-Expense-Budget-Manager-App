import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class RecurringListScreen extends StatelessWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      body: const EmptyStateView(
        icon: Icons.autorenew_outlined,
        title: 'No recurring expenses yet',
      ),
    );
  }
}
