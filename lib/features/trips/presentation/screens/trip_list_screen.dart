import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/trip.dart';
import '../../application/trip_providers.dart';
import '../widgets/trip_card.dart';

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Trip>> trips = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.tripCreate),
        child: const Icon(Icons.add),
      ),
      body: trips.when(
        data: (List<Trip> data) {
          if (data.isEmpty) {
            return const EmptyStateView(
              icon: Icons.flight_takeoff_outlined,
              title: 'No trips yet',
              message: 'Plan a trip to track its budget and expenses separately.',
            );
          }
          final List<Trip> sorted = <Trip>[...data]
            ..sort((Trip a, Trip b) => b.startDate.compareTo(a.startDate));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (BuildContext context, int index) =>
                TripCard(trip: sorted[index]),
          );
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }
}
