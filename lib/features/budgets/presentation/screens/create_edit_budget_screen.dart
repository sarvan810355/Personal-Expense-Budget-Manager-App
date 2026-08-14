import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/budget.dart';
import '../../../../domain/entities/budget_category.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/repositories/budget_repository.dart';

class CreateEditBudgetScreen extends ConsumerWidget {
  const CreateEditBudgetScreen({super.key, this.budgetId});

  final int? budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (budgetId == null) {
      return const _BudgetForm();
    }

    final AsyncValue<Budget?> existing = ref.watch(_budgetByIdProvider(budgetId!));
    final AsyncValue<List<BudgetCategory>> allocations =
        ref.watch(_allocationsForBudgetProvider(budgetId!));

    if (existing.isLoading || allocations.isLoading) {
      return const Scaffold(body: LoadingView());
    }
    if (existing.hasError) {
      return Scaffold(body: ErrorView(message: '${existing.error}'));
    }
    if (allocations.hasError) {
      return Scaffold(body: ErrorView(message: '${allocations.error}'));
    }

    return _BudgetForm(
      existing: existing.value,
      existingAllocations: allocations.value ?? const <BudgetCategory>[],
    );
  }
}

class _AllocationRow {
  _AllocationRow({this.id, this.categoryId, String? amount})
      : amountController = TextEditingController(text: amount ?? '');

  final int? id;
  int? categoryId;
  final TextEditingController amountController;
}

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({this.existing, this.existingAllocations = const <BudgetCategory>[]});

  final Budget? existing;
  final List<BudgetCategory> existingAllocations;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _totalController = TextEditingController(
    text: widget.existing?.totalAmount == null
        ? ''
        : widget.existing!.totalAmount.toStringAsFixed(2),
  );
  late BudgetPeriodType _periodType =
      widget.existing?.periodType ?? BudgetPeriodType.monthly;
  late DateTime _startDate =
      widget.existing?.startDate ?? AppDateUtils.startOfMonth(DateTime.now());
  late DateTime _endDate = widget.existing?.endDate ?? _endForPeriod(_periodType, _startDate);
  late final List<_AllocationRow> _allocations = <_AllocationRow>[
    for (final BudgetCategory a in widget.existingAllocations)
      _AllocationRow(
        id: a.id,
        categoryId: a.categoryId,
        amount: a.allocatedAmount.toStringAsFixed(2),
      ),
  ];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  static DateTime _endForPeriod(BudgetPeriodType type, DateTime start) {
    switch (type) {
      case BudgetPeriodType.weekly:
        return start.add(const Duration(days: 6));
      case BudgetPeriodType.monthly:
        return DateTime(start.year, start.month + 1, start.day)
            .subtract(const Duration(days: 1));
      case BudgetPeriodType.custom:
        return start;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalController.dispose();
    for (final _AllocationRow row in _allocations) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories = ref.watch(_expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Budget' : 'Create Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (String? v) => Validators.requiredText(v, field: 'Name'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<BudgetPeriodType>(
              segments: const <ButtonSegment<BudgetPeriodType>>[
                ButtonSegment<BudgetPeriodType>(
                  value: BudgetPeriodType.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment<BudgetPeriodType>(
                  value: BudgetPeriodType.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment<BudgetPeriodType>(
                  value: BudgetPeriodType.custom,
                  label: Text('Custom'),
                ),
              ],
              selected: <BudgetPeriodType>{_periodType},
              onSelectionChanged: (Set<BudgetPeriodType> s) {
                setState(() {
                  _periodType = s.first;
                  if (_periodType != BudgetPeriodType.custom) {
                    _endDate = _endForPeriod(_periodType, _startDate);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(AppDateUtils.formatShort(_startDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickStartDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End date'),
                    subtitle: Text(AppDateUtils.formatShort(_endDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _periodType == BudgetPeriodType.custom ? _pickEndDate : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalController,
              decoration: const InputDecoration(labelText: 'Total limit *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Category allocations', style: Theme.of(context).textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => setState(() => _allocations.add(_AllocationRow())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add category'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            categories.when(
              data: (List<Category> data) => Column(
                children: <Widget>[
                  for (final _AllocationRow row in _allocations)
                    _AllocationRowWidget(
                      row: row,
                      categories: data,
                      otherSelectedIds: _allocations
                          .where((_AllocationRow r) => r != row && r.categoryId != null)
                          .map((_AllocationRow r) => r.categoryId!)
                          .toSet(),
                      onCategoryChanged: (int? v) => setState(() => row.categoryId = v),
                      onRemove: () => setState(() {
                        _allocations.remove(row);
                        row.amountController.dispose();
                      }),
                    ),
                ],
              ),
              loading: () => const LoadingView(),
              error: (Object e, StackTrace st) => ErrorView(message: '$e'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Create budget'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_periodType != BudgetPeriodType.custom) {
          _endDate = _endForPeriod(_periodType, _startDate);
        } else if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    final Budget budget = Budget(
      id: widget.existing?.id ?? 0,
      name: _nameController.text.trim(),
      periodType: _periodType,
      startDate: _startDate,
      endDate: _endDate,
      totalAmount: double.parse(_totalController.text.trim()),
      alertThresholds: widget.existing?.alertThresholds ?? const <int>[80, 90, 100],
      createdAt: widget.existing?.createdAt ?? now,
    );

    final BudgetRepository repo = ref.read(budgetRepositoryProvider);
    final int id;
    if (_isEditing) {
      await repo.update(budget);
      id = budget.id;
    } else {
      id = await repo.create(budget);
    }

    final Set<int> keptAllocationIds = <int>{};
    for (final _AllocationRow row in _allocations) {
      if (row.categoryId == null) {
        continue;
      }
      final double amount = double.tryParse(row.amountController.text.trim()) ?? 0;
      if (row.id != null) {
        keptAllocationIds.add(row.id!);
        await repo.updateCategoryAllocation(
          BudgetCategory(
            id: row.id!,
            budgetId: id,
            categoryId: row.categoryId!,
            allocatedAmount: amount,
          ),
        );
      } else {
        await repo.addCategoryAllocation(
          BudgetCategory(id: 0, budgetId: id, categoryId: row.categoryId!, allocatedAmount: amount),
        );
      }
    }
    for (final BudgetCategory existingAllocation in widget.existingAllocations) {
      if (!keptAllocationIds.contains(existingAllocation.id)) {
        await repo.removeCategoryAllocation(existingAllocation.id);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _AllocationRowWidget extends StatelessWidget {
  const _AllocationRowWidget({
    required this.row,
    required this.categories,
    required this.otherSelectedIds,
    required this.onCategoryChanged,
    required this.onRemove,
  });

  final _AllocationRow row;
  final List<Category> categories;
  final Set<int> otherSelectedIds;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final List<Category> options = categories
        .where((Category c) => c.id == row.categoryId || !otherSelectedIds.contains(c.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              value: row.categoryId != null && options.any((Category c) => c.id == row.categoryId)
                  ? row.categoryId
                  : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: <DropdownMenuItem<int>>[
                for (final Category c in options)
                  DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
              ],
              onChanged: onCategoryChanged,
              validator: (int? v) => v == null ? 'Pick a category' : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: row.amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

final StreamProvider<List<Category>> _expenseCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchByType(CategoryType.expense),
);

final FutureProviderFamily<Budget?, int> _budgetByIdProvider =
    FutureProvider.family<Budget?, int>(
  (Ref ref, int id) => ref.watch(budgetRepositoryProvider).getById(id),
);

final FutureProviderFamily<List<BudgetCategory>, int> _allocationsForBudgetProvider =
    FutureProvider.family<List<BudgetCategory>, int>(
  (Ref ref, int budgetId) =>
      ref.watch(budgetRepositoryProvider).watchCategoriesForBudget(budgetId).first,
);
