import 'package:flutter/material.dart';

import '../../../../core/services/calculation_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/budget.dart';
import '../../../budgets/application/budget_progress.dart';
import '../../../budgets/presentation/widgets/budget_progress_bar.dart';

const CalculationService _calculationService = CalculationService();

/// Every budget's spend-vs-allocation, reusing [BudgetProgressBar] and
/// [BudgetProgress] so the figures match the Budgets and Dashboard screens
/// exactly.
class BudgetAdherenceList extends StatelessWidget {
  const BudgetAdherenceList({required this.progress, required this.formatter, super.key});

  final List<BudgetProgress> progress;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final BudgetProgress p in progress)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _BudgetAdherenceTile(progress: p, formatter: formatter),
          ),
      ],
    );
  }
}

class _BudgetAdherenceTile extends StatelessWidget {
  const _BudgetAdherenceTile({required this.progress, required this.formatter});

  final BudgetProgress progress;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final Budget budget = progress.budget;
    final double ratio = budget.totalAmount <= 0
        ? 0
        : (progress.spent / budget.totalAmount).clamp(0, 1).toDouble();
    final bool overBudget = progress.spent > budget.totalAmount;
    final double percentUsed =
        _calculationService.budgetPercentUsed(budget.totalAmount, progress.spent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(child: Text(budget.name, style: Theme.of(context).textTheme.titleSmall)),
            Text(
              '${percentUsed.round()}%',
              style: TextStyle(
                color: overBudget ? Theme.of(context).colorScheme.error : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BudgetProgressBar(ratio: ratio, overBudget: overBudget),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('${formatter.format(progress.spent)} spent'),
            Text('of ${formatter.format(budget.totalAmount)}'),
          ],
        ),
      ],
    );
  }
}
