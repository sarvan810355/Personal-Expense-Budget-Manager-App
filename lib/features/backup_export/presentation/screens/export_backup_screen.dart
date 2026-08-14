import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class ExportBackupScreen extends StatelessWidget {
  const ExportBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: const EmptyStateView(
        icon: Icons.ios_share_outlined,
        title: 'CSV/Excel/PDF export coming in Phase 7',
      ),
    );
  }
}
