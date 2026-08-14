import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/category.dart';
import '../../application/expense_filter.dart';

/// Bottom sheet for filtering the Expense List by date range, category,
/// payment method, and amount range (§7 of the master prompt). Presented
/// via `showModalBottomSheet`; returns the chosen [ExpenseFilter] (or
/// `null` if dismissed without changes).
class ExpenseFilterSheet extends ConsumerStatefulWidget {
  const ExpenseFilterSheet({required this.initial, super.key});

  final ExpenseFilter initial;

  @override
  ConsumerState<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<ExpenseFilterSheet> {
  late ExpenseFilter _filter = widget.initial;
  late final TextEditingController _minController =
      TextEditingController(text: widget.initial.minAmount?.toStringAsFixed(0) ?? '');
  late final TextEditingController _maxController =
      TextEditingController(text: widget.initial.maxAmount?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyDatePreset(DateTime? start, DateTime? end) {
    setState(() => _filter = _filter.copyWith(
          start: start,
          end: end,
          clearDateRange: start == null && end == null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories =
        ref.watch(_expenseCategoriesProvider);
    final DateTime now = DateTime.now();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => setState(() => _filter = const ExpenseFilter()),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _presetChip('Today', AppDateUtils.startOfDay(now), AppDateUtils.endOfDay(now)),
                _presetChip(
                  'Yesterday',
                  AppDateUtils.startOfDay(now.subtract(const Duration(days: 1))),
                  AppDateUtils.endOfDay(now.subtract(const Duration(days: 1))),
                ),
                _presetChip(
                  'This Week',
                  AppDateUtils.startOfDay(now.subtract(Duration(days: now.weekday - 1))),
                  AppDateUtils.endOfDay(now),
                ),
                _presetChip('This Month', AppDateUtils.startOfMonth(now), AppDateUtils.endOfMonth(now)),
                _presetChip(
                  'Last Month',
                  AppDateUtils.startOfMonth(DateTime(now.year, now.month - 1)),
                  AppDateUtils.endOfMonth(DateTime(now.year, now.month - 1)),
                ),
                ActionChip(
                  label: const Text('Custom range'),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            categories.when(
              data: (List<Category> data) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Category c in data)
                    FilterChip(
                      label: Text(c.name),
                      selected: _filter.categoryId == c.id,
                      onSelected: (bool selected) => setState(() {
                        _filter = _filter.copyWith(
                          categoryId: selected ? c.id : null,
                          clearCategory: !selected,
                        );
                      }),
                    ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (Object e, StackTrace st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Text('Payment method', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String method in kPaymentMethods)
                  FilterChip(
                    label: Text(method),
                    selected: _filter.paymentMethod == method,
                    onSelected: (bool selected) => setState(() {
                      _filter = _filter.copyWith(
                        paymentMethod: selected ? method : null,
                        clearPaymentMethod: !selected,
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Amount range', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final double? min = double.tryParse(_minController.text.trim());
                final double? max = double.tryParse(_maxController.text.trim());
                Navigator.of(context).pop(
                  _filter.copyWith(
                    minAmount: min,
                    maxAmount: max,
                    clearAmountRange: min == null && max == null,
                  ),
                );
              },
              child: const Text('Apply filters'),
            ),
          ],
        );
      },
    );
  }

  Widget _presetChip(String label, DateTime start, DateTime end) {
    final bool selected = _filter.start == start && _filter.end == end;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) => _applyDatePreset(value ? start : null, value ? end : null),
    );
  }

  Future<void> _pickCustomRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _filter.start != null && _filter.end != null
          ? DateTimeRange(start: _filter.start!, end: _filter.end!)
          : null,
    );
    if (range != null) {
      _applyDatePreset(
        AppDateUtils.startOfDay(range.start),
        AppDateUtils.endOfDay(range.end),
      );
    }
  }
}

final StreamProvider<List<Category>> _expenseCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchByType(CategoryType.expense),
);
