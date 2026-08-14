import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Trip #$tripId'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Overview'),
              Tab(text: 'Expenses'),
              Tab(text: 'Day-wise'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            EmptyStateView(icon: Icons.flight_outlined, title: 'Trip overview coming in Phase 5'),
            EmptyStateView(icon: Icons.receipt_long_outlined, title: 'Trip expenses coming in Phase 5'),
            EmptyStateView(icon: Icons.calendar_view_day_outlined, title: 'Day-wise view coming in Phase 5'),
          ],
        ),
      ),
    );
  }
}
