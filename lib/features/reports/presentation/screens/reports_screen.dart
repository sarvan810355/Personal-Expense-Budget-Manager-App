import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const EmptyStateView(
        icon: Icons.bar_chart_outlined,
        title: 'Reports & charts coming in Phase 6',
      ),
    );
  }
}
