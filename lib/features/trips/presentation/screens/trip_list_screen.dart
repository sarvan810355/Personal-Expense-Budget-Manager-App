import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: const EmptyStateView(
        icon: Icons.flight_takeoff_outlined,
        title: 'No trips yet',
        message: 'Plan a trip to track its budget and expenses separately.',
      ),
    );
  }
}
