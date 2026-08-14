import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class ReceiptViewerScreen extends StatelessWidget {
  const ReceiptViewerScreen({required this.expenseId, super.key});

  final int expenseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Receipt'),
      ),
      body: const EmptyStateView(
        icon: Icons.image_outlined,
        title: 'Receipt capture coming in Phase 7',
      ),
    );
  }
}
