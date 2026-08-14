import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../domain/entities/category.dart';
import '../../../budgets/presentation/widgets/budget_progress_bar.dart';
import '../../application/trip_providers.dart';

/// Single category budget row (icon, name, progress bar, spend vs
/// allocation), used by the trip detail screen's Overview tab.
class TripCategoryBudgetTile extends ConsumerWidget {
  const TripCategoryBudgetTile({required this.spend, required this.formatter, super.key});

  final TripCategorySpend spend;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Category?> category =
        ref.watch(_categoryByIdProvider(spend.allocation.categoryId));
    final double allocated = spend.allocation.allocatedAmount;
    final double ratio = allocated <= 0 ? 0 : (spend.spent / allocated).clamp(0, 1).toDouble();
    final bool over = spend.spent > allocated;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CategoryIconAvatar(
            iconName: category.value?.icon ?? 'category',
            color: category.value?.color ?? 0xFF757575,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(category.value?.name ?? '—'),
                const SizedBox(height: 4),
                BudgetProgressBar(ratio: ratio, overBudget: over, minHeight: 6),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(spend.spent)} of ${formatter.format(allocated)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final FutureProviderFamily<Category?, int> _categoryByIdProvider =
    FutureProvider.family<Category?, int>(
  (Ref ref, int id) => ref.watch(categoryRepositoryProvider).getById(id),
);
