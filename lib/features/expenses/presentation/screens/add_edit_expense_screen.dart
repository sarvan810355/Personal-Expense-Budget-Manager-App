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
import '../../application/expense_filter.dart';

class AddEditExpenseScreen extends ConsumerWidget {
  const AddEditExpenseScreen({super.key, this.expenseId});

  final int? expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenseId == null) {
      return const _ExpenseForm();
    }
    final AsyncValue<Expense?> existing =
        ref.watch(_expenseByIdProvider(expenseId!));
    return existing.when(
      data: (Expense? expense) => _ExpenseForm(existing: expense),
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object e, StackTrace st) =>
          Scaffold(body: ErrorView(message: '$e')),
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.existing});

  final Expense? existing;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
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
  late final TextEditingController _locationController =
      TextEditingController(text: widget.existing?.location ?? '');

  late int? _categoryId = widget.existing?.categoryId;
  late int? _accountId = widget.existing?.accountId;
  late String? _paymentMethod = widget.existing?.paymentMethod;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late TimeOfDay? _time = widget.existing?.time != null
      ? _parseTime(widget.existing!.time!)
      : TimeOfDay.now();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  static TimeOfDay? _parseTime(String value) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

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
    final AsyncValue<List<Category>> categories = ref.watch(_expenseCategoriesProvider);
    final AsyncValue<List<Account>> accounts = ref.watch(_accountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
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
              child: Text(_isEditing ? 'Save changes' : 'Add expense'),
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
      id: widget.existing?.id ?? 0,
      amount: double.parse(_amountController.text.trim()),
      title: _titleController.text.trim(),
      categoryId: _categoryId!,
      accountId: _accountId!,
      tripId: widget.existing?.tripId,
      date: _date,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      time: _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      paymentMethod: _paymentMethod,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      receiptPath: widget.existing?.receiptPath,
    );

    if (_isEditing) {
      await ref.read(expenseRepositoryProvider).update(expense);
    } else {
      await ref.read(expenseRepositoryProvider).create(expense);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

final StreamProvider<List<Category>> _expenseCategoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchByType(CategoryType.expense),
);

final StreamProvider<List<Account>> _accountsProvider =
    StreamProvider<List<Account>>(
  (Ref ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

final FutureProviderFamily<Expense?, int> _expenseByIdProvider =
    FutureProvider.family<Expense?, int>(
  (Ref ref, int id) => ref.watch(expenseRepositoryProvider).getById(id),
);
