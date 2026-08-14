import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/recurring_expense.dart';
import '../../application/recurring_providers.dart';

class AddEditRecurringScreen extends ConsumerWidget {
  const AddEditRecurringScreen({super.key, this.recurringId});

  final int? recurringId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recurringId == null) {
      return const _RecurringForm();
    }
    final AsyncValue<RecurringExpense?> existing =
        ref.watch(recurringByIdProvider(recurringId!));
    return existing.when(
      data: (RecurringExpense? recurringExpense) =>
          _RecurringForm(existing: recurringExpense),
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object e, StackTrace st) => Scaffold(body: ErrorView(message: '$e')),
    );
  }
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({this.existing});

  final RecurringExpense? existing;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _amountController = TextEditingController(
    text: widget.existing?.amount == null
        ? ''
        : widget.existing!.amount.toStringAsFixed(2),
  );
  late final TextEditingController _noteController =
      TextEditingController(text: widget.existing?.note ?? '');

  late int? _categoryId = widget.existing?.categoryId;
  late int? _accountId = widget.existing?.accountId;
  late RecurringFrequency _frequency =
      widget.existing?.frequency ?? RecurringFrequency.monthly;
  late DateTime _startDate = widget.existing?.startDate ?? DateTime.now();
  late DateTime _nextDate = widget.existing?.nextDate ?? _startDate;
  DateTime? _endDate = widget.existing?.endDate;
  late bool _active = widget.existing?.active ?? true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories = ref.watch(recurringCategoriesProvider);
    final AsyncValue<List<Account>> accounts = ref.watch(recurringAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Recurring Expense' : 'Add Recurring Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (String? v) => Validators.requiredText(v, field: 'Title'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: 16),
            categories.when(
              data: (List<Category> data) => DropdownButtonFormField<int>(
                value: _categoryId != null && data.any((Category c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: <DropdownMenuItem<int>>[
                  for (final Category c in data)
                    DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (int? v) => setState(() => _categoryId = v),
                validator: (int? v) => v == null ? 'Category is required' : null,
              ),
              loading: () => const LoadingView(),
              error: (Object e, StackTrace st) => ErrorView(message: '$e'),
            ),
            const SizedBox(height: 16),
            accounts.when(
              data: (List<Account> data) => DropdownButtonFormField<int>(
                value: _accountId != null && data.any((Account a) => a.id == _accountId)
                    ? _accountId
                    : null,
                decoration: const InputDecoration(labelText: 'Account *'),
                items: <DropdownMenuItem<int>>[
                  for (final Account a in data)
                    DropdownMenuItem<int>(value: a.id, child: Text(a.name)),
                ],
                onChanged: (int? v) => setState(() => _accountId = v),
                validator: (int? v) => v == null ? 'Account is required' : null,
              ),
              loading: () => const LoadingView(),
              error: (Object e, StackTrace st) => ErrorView(message: '$e'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurringFrequency>(
              value: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency *'),
              items: <DropdownMenuItem<RecurringFrequency>>[
                for (final RecurringFrequency f in RecurringFrequency.values)
                  DropdownMenuItem<RecurringFrequency>(
                    value: f,
                    child: Text(recurringFrequencyLabel(f)),
                  ),
              ],
              onChanged: (RecurringFrequency? v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(AppDateUtils.formatShort(_startDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next due date'),
              subtitle: Text(AppDateUtils.formatShort(_nextDate)),
              trailing: const Icon(Icons.event_outlined),
              onTap: _pickNextDate,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date'),
              subtitle: Text(_endDate == null ? 'None' : AppDateUtils.formatShort(_endDate!)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  const Icon(Icons.calendar_today_outlined),
                ],
              ),
              onTap: _pickEndDate,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Paused recurring expenses are kept but no longer due'),
              value: _active,
              onChanged: (bool v) => setState(() => _active = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Add recurring expense'),
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
      });
    }
  }

  Future<void> _pickNextDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _nextDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: DateTime(2000),
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
    setState(() => _saving = true);
    final RecurringExpense recurringExpense = RecurringExpense(
      id: widget.existing?.id ?? 0,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      categoryId: _categoryId!,
      accountId: _accountId!,
      frequency: _frequency,
      startDate: _startDate,
      nextDate: _nextDate,
      active: _active,
      endDate: _endDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(recurringRepositoryProvider).update(recurringExpense);
    } else {
      await ref.read(recurringRepositoryProvider).create(recurringExpense);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
