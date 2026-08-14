import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/income.dart';
import '../../application/income_providers.dart';

class AddEditIncomeScreen extends ConsumerWidget {
  const AddEditIncomeScreen({super.key, this.incomeId});

  final int? incomeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (incomeId == null) {
      return const _IncomeForm();
    }
    final AsyncValue<Income?> existing = ref.watch(incomeByIdProvider(incomeId!));
    return existing.when(
      data: (Income? income) => _IncomeForm(existing: income),
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object e, StackTrace st) => Scaffold(body: ErrorView(message: '$e')),
    );
  }
}

class _IncomeForm extends ConsumerStatefulWidget {
  const _IncomeForm({this.existing});

  final Income? existing;

  @override
  ConsumerState<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<_IncomeForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController = TextEditingController(
    text: widget.existing?.amount == null
        ? ''
        : widget.existing!.amount.toStringAsFixed(2),
  );
  late final TextEditingController _noteController =
      TextEditingController(text: widget.existing?.note ?? '');

  late IncomeSource _source = widget.existing?.source ?? IncomeSource.salary;
  late int? _categoryId = widget.existing?.categoryId;
  late int? _accountId = widget.existing?.accountId;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories = ref.watch(incomeCategoriesProvider);
    final AsyncValue<List<Account>> accounts = ref.watch(incomeAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Income' : 'Add Income')),
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
            DropdownButtonFormField<IncomeSource>(
              value: _source,
              decoration: const InputDecoration(labelText: 'Source *'),
              items: <DropdownMenuItem<IncomeSource>>[
                for (final IncomeSource s in IncomeSource.values)
                  DropdownMenuItem<IncomeSource>(
                    value: s,
                    child: Text(incomeSourceLabel(s)),
                  ),
              ],
              onChanged: (IncomeSource? v) => setState(() => _source = v!),
            ),
            const SizedBox(height: 16),
            categories.when(
              data: (List<Category> data) => DropdownButtonFormField<int?>(
                value: _categoryId != null && data.any((Category c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(value: null, child: Text('None')),
                  for (final Category c in data)
                    DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (int? v) => setState(() => _categoryId = v),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(AppDateUtils.formatShort(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
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
              child: Text(_isEditing ? 'Save changes' : 'Add income'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    final Income income = Income(
      id: widget.existing?.id ?? 0,
      amount: double.parse(_amountController.text.trim()),
      source: _source,
      accountId: _accountId!,
      date: _date,
      createdAt: widget.existing?.createdAt ?? now,
      categoryId: _categoryId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(incomeRepositoryProvider).update(income);
    } else {
      await ref.read(incomeRepositoryProvider).create(income);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
