import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/application/dashboard_providers.dart' show CategorySpend;

/// Pie chart plus a ranked list of category spend, colored using each
/// category's stored tint so it matches how the category renders
/// elsewhere in the app.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({required this.data, required this.formatter, super.key});

  final List<CategorySpend> data;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final double total = data.fold(0, (double sum, CategorySpend s) => sum + s.amount);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: <PieChartSectionData>[
                for (final CategorySpend spend in data)
                  PieChartSectionData(
                    value: spend.amount,
                    color: Color(spend.category.color),
                    title: total <= 0 ? '' : '${(spend.amount / total * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final CategorySpend spend in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(spend.category.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(spend.category.name)),
                Text(formatter.format(spend.amount)),
              ],
            ),
          ),
      ],
    );
  }
}
