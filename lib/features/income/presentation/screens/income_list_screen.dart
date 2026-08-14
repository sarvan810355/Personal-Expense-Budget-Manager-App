import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class IncomeListScreen extends StatelessWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: const EmptyStateView(
        icon: Icons.attach_money_outlined,
        title: 'No income recorded yet',
      ),
    );
  }
}
