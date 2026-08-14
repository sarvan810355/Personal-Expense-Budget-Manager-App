import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AddEditIncomeScreen extends StatelessWidget {
  const AddEditIncomeScreen({super.key, this.incomeId});

  final int? incomeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(incomeId == null ? 'Add Income' : 'Edit Income')),
      body: const EmptyStateView(
        icon: Icons.edit_outlined,
        title: 'Income form coming in Phase 3',
      ),
    );
  }
}
