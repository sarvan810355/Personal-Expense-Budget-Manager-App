import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class CreateEditTripScreen extends StatelessWidget {
  const CreateEditTripScreen({super.key, this.tripId});

  final int? tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tripId == null ? 'Create Trip' : 'Edit Trip')),
      body: const EmptyStateView(
        icon: Icons.add_location_alt_outlined,
        title: 'Trip form coming in Phase 5',
      ),
    );
  }
}
