import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../budgets/application/budget_progress.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../application/reports_providers.dart';
import '../widgets/budget_adherence_list.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/monthly_trend_chart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Category'),
              Tab(text: 'Trends'),
              Tab(text: 'Budgets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _CategoryTab(),
            _TrendsTab(),
            _BudgetsTab(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReportPeriod period = ref.watch(selectedReportPeriodProvider);
    final AsyncValue<List<CategorySpend>> breakdown =
        ref.watch(reportCategoryBreakdownProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        SegmentedButton<ReportPeriod>(
          segments: <ButtonSegment<ReportPeriod>>[
            for (final ReportPeriod p in ReportPeriod.values)
              ButtonSegment<ReportPeriod>(value: p, label: Text(p.label)),
          ],
          selected: <ReportPeriod>{period},
          onSelectionChanged: (Set<ReportPeriod> selection) {
            ref.read(selectedReportPeriodProvider.notifier).state = selection.first;
          },
        ),
        const SizedBox(height: 16),
        breakdown.when(
          data: (List<CategorySpend> data) {
            if (data.isEmpty) {
              return const AppCard(
                child: Text('No expenses recorded for this period yet.'),
              );
            }
            return AppCard(child: CategoryPieChart(data: data, formatter: formatter));
          },
          loading: () => const AppCard(child: LoadingView()),
          error: (Object e, StackTrace st) => AppCard(child: ErrorView(message: '$e')),
        ),
      ],
    );
  }
}

class _TrendsTab extends ConsumerWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MonthlyTrendPoint>> trend = ref.watch(monthlyTrendProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        trend.when(
          data: (List<MonthlyTrendPoint> data) {
            if (data.every((MonthlyTrendPoint p) => p.income == 0 && p.expense == 0)) {
              return const AppCard(
                child: Text('No income or expenses recorded in the last 6 months yet.'),
              );
            }
            return AppCard(child: MonthlyTrendChart(points: data));
          },
          loading: () => const AppCard(child: LoadingView()),
          error: (Object e, StackTrace st) => AppCard(child: ErrorView(message: '$e')),
        ),
      ],
    );
  }
}

class _BudgetsTab extends ConsumerWidget {
  const _BudgetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BudgetProgress>> progress =
        ref.watch(dashboardBudgetProgressProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final CurrencyFormatter formatter =
        CurrencyFormatter(settings.value?.currencyCode ?? 'INR');

    return progress.when(
      data: (List<BudgetProgress> data) {
        if (data.isEmpty) {
          return const EmptyStateView(
            icon: Icons.pie_chart_outline,
            title: 'No budgets yet',
            message: 'Create a budget from the Budgets tab to see adherence here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            BudgetAdherenceList(progress: data, formatter: formatter),
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (Object e, StackTrace st) => ErrorView(message: '$e'),
    );
  }
}
