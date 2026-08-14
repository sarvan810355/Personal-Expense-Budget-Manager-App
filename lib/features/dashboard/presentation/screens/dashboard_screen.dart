import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const EmptyStateView(
        icon: Icons.dashboard_outlined,
        title: 'Your dashboard is empty',
        message: 'Once you add expenses and income, your summary will show up here.',
      ),
    );
  }
}
