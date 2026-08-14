import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AddEditAccountScreen extends StatelessWidget {
  const AddEditAccountScreen({super.key, this.accountId});

  final int? accountId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(accountId == null ? 'Add Account' : 'Edit Account')),
      body: const EmptyStateView(
        icon: Icons.edit_outlined,
        title: 'Account form coming in Phase 2',
      ),
    );
  }
}
