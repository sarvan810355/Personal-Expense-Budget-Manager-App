import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/trip.dart';
import '../../../budgets/presentation/widgets/budget_progress_bar.dart';
import '../../application/trip_providers.dart';

/// Single trip card (name, destination, date range, spend-vs-budget
/// progress), used by the Trips list.
class TripCard extends ConsumerWidget {
  const TripCard({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TripProgress?> progress = ref.watch(tripProgressProvider(trip.id));
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

    final double spent = progress.value?.spent ?? 0;
    final double ratio = trip.totalBudget <= 0
        ? 0
        : (spent / trip.totalBudget).clamp(0, 1).toDouble();
    final bool overBudget = spent > trip.totalBudget;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(Routes.tripDetailPath(trip.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(trip.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                trip.destination,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppDateUtils.formatDay(trip.startDate)} - '
                '${AppDateUtils.formatDay(trip.endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              BudgetProgressBar(ratio: ratio, overBudget: overBudget),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('${formatter.format(spent)} spent'),
                  Text('of ${formatter.format(trip.totalBudget)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
