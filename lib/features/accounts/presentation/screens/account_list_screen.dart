import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/app_settings.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  static const Map<AccountType, IconData> _icons = <AccountType, IconData>{
    AccountType.cash: Icons.payments_outlined,
    AccountType.bank: Icons.account_balance_outlined,
    AccountType.upi: Icons.qr_code_outlined,
    AccountType.card: Icons.credit_card_outlined,
    AccountType.wallet: Icons.account_balance_wallet_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Account>> accounts = ref.watch(_accountsProvider);
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.accountAdd),
        child: const Icon(Icons.add),
      ),
      body: accounts.when(
        data: (List<Account> data) {
          if (data.isEmpty) {
            return const EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              message:
                  'Add a cash, bank, or card account to start tracking expenses.',
            );
          }
          final CurrencyFormatter formatter = CurrencyFormatter(
            settings.value?.currencyCode ?? 'INR',
          );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (BuildContext context, int index) {
              final Account account = data[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () =>
                      context.push(Routes.accountEditPath(account.id)),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            Color(account.color).withOpacity(0.15),
                        child: Icon(
                          _icons[account.type] ?? Icons.account_balance_wallet,
                          color: Color(account.color),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(account.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              account.type.name.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatter.format(account.balance),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String action) async {
                          if (action == 'edit') {
                            context.push(Routes.accountEditPath(account.id));
                          } else if (action == 'delete') {
                            await _confirmDelete(context, ref, account);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            const <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                          PopupMenuItem<String>(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text('Delete "${account.name}"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(accountRepositoryProvider).delete(account.id);
    }
  }
}

final StreamProvider<List<Account>> _accountsProvider =
    StreamProvider<List<Account>>(
  (Ref ref) => ref.watch(accountRepositoryProvider).watchAll(),
);
