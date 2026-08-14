import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const EmptyStateView(
        icon: Icons.calendar_month_outlined,
        title: 'Calendar view coming in Phase 2',
      ),
    );
  }
}
