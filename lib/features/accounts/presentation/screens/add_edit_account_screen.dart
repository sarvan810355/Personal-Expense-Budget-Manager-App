import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/icon_map.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';

class AddEditAccountScreen extends ConsumerWidget {
  const AddEditAccountScreen({super.key, this.accountId});

  final int? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accountId == null) {
      return const _AccountForm();
    }
    final AsyncValue<Account?> existing =
        ref.watch(_accountByIdProvider(accountId!));
    return existing.when(
      data: (Account? account) => _AccountForm(existing: account),
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object e, StackTrace st) =>
          Scaffold(body: ErrorView(message: '$e')),
    );
  }
}

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({this.existing});

  final Account? existing;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  static const Map<AccountType, String> _typeIcon = <AccountType, String>{
    AccountType.cash: 'attach_money',
    AccountType.bank: 'bank',
    AccountType.upi: 'wallet',
    AccountType.card: 'credit_card',
    AccountType.wallet: 'wallet',
  };

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _balanceController = TextEditingController(
    text: widget.existing?.balance.toStringAsFixed(2) ?? '0.00',
  );
  late AccountType _type = widget.existing?.type ?? AccountType.cash;
  late int _color = widget.existing?.color ?? kColorPalette.first;
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Account' : 'Add Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Account name'),
              validator: (String? v) =>
                  Validators.requiredText(v, field: 'Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: <DropdownMenuItem<AccountType>>[
                for (final AccountType t in AccountType.values)
                  DropdownMenuItem<AccountType>(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  ),
              ],
              onChanged: (AccountType? v) =>
                  setState(() => _type = v ?? AccountType.cash),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Starting balance',
                prefixText: '',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Balance is required';
                }
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Inactive accounts are hidden from pickers'),
              value: _isActive,
              onChanged: (bool v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int c in kColorPalette)
                  InkWell(
                    onTap: () => setState(() => _color = c),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(c),
                      child: c == _color
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Add account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final Account account = Account(
      id: widget.existing?.id ?? 0,
      name: _nameController.text.trim(),
      type: _type,
      balance: double.parse(_balanceController.text.trim()),
      icon: _typeIcon[_type] ?? 'wallet',
      color: _color,
      isActive: _isActive,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      await ref.read(accountRepositoryProvider).update(account);
    } else {
      await ref.read(accountRepositoryProvider).create(account);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

final FutureProviderFamily<Account?, int> _accountByIdProvider =
    FutureProvider.family<Account?, int>(
  (Ref ref, int id) => ref.watch(accountRepositoryProvider).getById(id),
);
