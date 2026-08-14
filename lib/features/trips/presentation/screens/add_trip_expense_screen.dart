import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AddTripExpenseScreen extends StatelessWidget {
  const AddTripExpenseScreen({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip Expense')),
      body: const EmptyStateView(
        icon: Icons.add_card_outlined,
        title: 'Trip expense form coming in Phase 5',
      ),
    );
  }
}
