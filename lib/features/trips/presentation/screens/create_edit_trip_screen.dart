import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../domain/entities/trip_category_budget.dart';
import '../../../../domain/repositories/trip_repository.dart';
import '../../application/trip_providers.dart';

class CreateEditTripScreen extends ConsumerWidget {
  const CreateEditTripScreen({super.key, this.tripId});

  final int? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tripId == null) {
      return const _TripForm();
    }

    final AsyncValue<Trip?> existing = ref.watch(tripByIdProvider(tripId!));
    final AsyncValue<List<TripCategoryBudget>> allocations =
        ref.watch(tripCategoryBudgetsProvider(tripId!));

    if (existing.isLoading || allocations.isLoading) {
      return const Scaffold(body: LoadingView());
    }
    if (existing.hasError) {
      return Scaffold(body: ErrorView(message: '${existing.error}'));
    }
    if (allocations.hasError) {
      return Scaffold(body: ErrorView(message: '${allocations.error}'));
    }

    return _TripForm(
      existing: existing.value,
      existingAllocations: allocations.value ?? const <TripCategoryBudget>[],
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

class _TripForm extends ConsumerStatefulWidget {
  const _TripForm({this.existing, this.existingAllocations = const <TripCategoryBudget>[]});

  final Trip? existing;
  final List<TripCategoryBudget> existingAllocations;

  @override
  ConsumerState<_TripForm> createState() => _TripFormState();
}

class _TripFormState extends ConsumerState<_TripForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _destinationController =
      TextEditingController(text: widget.existing?.destination ?? '');
  late final TextEditingController _totalBudgetController = TextEditingController(
    text: widget.existing?.totalBudget == null
        ? ''
        : widget.existing!.totalBudget.toStringAsFixed(2),
  );
  late final TextEditingController _notesController =
      TextEditingController(text: widget.existing?.notes ?? '');

  late DateTime _startDate = widget.existing?.startDate ?? DateTime.now();
  late DateTime _endDate = widget.existing?.endDate ?? _startDate;
  late final List<_AllocationRow> _allocations = <_AllocationRow>[
    for (final TripCategoryBudget a in widget.existingAllocations)
      _AllocationRow(
        id: a.id,
        categoryId: a.categoryId,
        amount: a.allocatedAmount.toStringAsFixed(2),
      ),
  ];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _totalBudgetController.dispose();
    _notesController.dispose();
    for (final _AllocationRow row in _allocations) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories = ref.watch(tripExpenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Trip' : 'Create Trip')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Trip name *'),
              validator: (String? v) => Validators.requiredText(v, field: 'Trip name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination *'),
              validator: (String? v) => Validators.requiredText(v, field: 'Destination'),
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
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalBudgetController,
              decoration: const InputDecoration(labelText: 'Total budget *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Category budgets', style: Theme.of(context).textTheme.titleSmall),
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
              child: Text(_isEditing ? 'Save changes' : 'Create trip'),
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
        if (_endDate.isBefore(_startDate)) {
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
    final Trip trip = Trip(
      id: widget.existing?.id ?? 0,
      name: _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      totalBudget: double.parse(_totalBudgetController.text.trim()),
      createdAt: widget.existing?.createdAt ?? now,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final TripRepository repo = ref.read(tripRepositoryProvider);
    final int id;
    if (_isEditing) {
      await repo.update(trip);
      id = trip.id;
    } else {
      id = await repo.create(trip);
    }

    final Set<int> keptAllocationIds = <int>{};
    for (final _AllocationRow row in _allocations) {
      if (row.categoryId == null) {
        continue;
      }
      final double amount = double.tryParse(row.amountController.text.trim()) ?? 0;
      if (row.id != null) {
        keptAllocationIds.add(row.id!);
        await repo.updateCategoryBudget(
          TripCategoryBudget(
            id: row.id!,
            tripId: id,
            categoryId: row.categoryId!,
            allocatedAmount: amount,
          ),
        );
      } else {
        await repo.addCategoryBudget(
          TripCategoryBudget(id: 0, tripId: id, categoryId: row.categoryId!, allocatedAmount: amount),
        );
      }
    }
    for (final TripCategoryBudget existingAllocation in widget.existingAllocations) {
      if (!keptAllocationIds.contains(existingAllocation.id)) {
        await repo.removeCategoryBudget(existingAllocation.id);
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
