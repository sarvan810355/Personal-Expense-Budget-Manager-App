import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AccountListScreen extends StatelessWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: const EmptyStateView(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No accounts yet',
        message: 'Add a cash, bank, or card account to start tracking expenses.',
      ),
    );
  }
}
