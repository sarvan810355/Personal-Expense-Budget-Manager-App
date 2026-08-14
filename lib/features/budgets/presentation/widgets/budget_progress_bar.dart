import 'package:flutter/material.dart';

/// Thin rounded progress bar showing spend against a limit, switching to
/// the theme's error color when over budget. Shared by the Budgets list,
/// budget detail, and the Dashboard's budget progress section.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.ratio,
    super.key,
    this.overBudget = false,
    this.minHeight = 8,
  });

  final double ratio;
  final bool overBudget;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: minHeight,
        color: overBudget ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}
