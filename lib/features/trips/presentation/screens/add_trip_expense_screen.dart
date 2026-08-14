import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/expense.dart';
import '../../../expenses/application/expense_filter.dart';
import '../../application/trip_providers.dart';

class AddTripExpenseScreen extends ConsumerStatefulWidget {
  const AddTripExpenseScreen({required this.tripId, super.key});

  final int tripId;

  @override
  ConsumerState<AddTripExpenseScreen> createState() => _AddTripExpenseScreenState();
}

class _AddTripExpenseScreenState extends ConsumerState<AddTripExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  int? _categoryId;
  int? _accountId;
  String? _paymentMethod;
  DateTime _date = DateTime.now();
  TimeOfDay? _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories = ref.watch(tripExpenseCategoriesProvider);
    final AsyncValue<List<Account>> accounts = ref.watch(tripAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (String? v) => Validators.requiredText(v, field: 'Title'),
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
            Row(
              children: <Widget>[
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(AppDateUtils.formatShort(_date)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time'),
                    subtitle: Text(_time?.format(context) ?? 'Not set'),
                    trailing: const Icon(Icons.access_time_outlined),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: <DropdownMenuItem<String>>[
                for (final String m in kPaymentMethods)
                  DropdownMenuItem<String>(value: m, child: Text(m)),
              ],
              onChanged: (String? v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
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
              child: const Text('Add expense'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    final Expense expense = Expense(
      id: 0,
      amount: double.parse(_amountController.text.trim()),
      title: _titleController.text.trim(),
      categoryId: _categoryId!,
      accountId: _accountId!,
      tripId: widget.tripId,
      date: _date,
      createdAt: now,
      updatedAt: now,
      time: _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      paymentMethod: _paymentMethod,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    );

    await ref.read(expenseRepositoryProvider).create(expense);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
