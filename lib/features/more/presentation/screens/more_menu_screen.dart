import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  static const List<_MoreMenuItem> _items = <_MoreMenuItem>[
    _MoreMenuItem(icon: Icons.attach_money_outlined, label: 'Income', route: Routes.income),
    _MoreMenuItem(icon: Icons.flight_takeoff_outlined, label: 'Trips', route: Routes.trips),
    _MoreMenuItem(icon: Icons.category_outlined, label: 'Categories', route: Routes.categories),
    _MoreMenuItem(icon: Icons.account_balance_wallet_outlined, label: 'Accounts', route: Routes.accounts),
    _MoreMenuItem(icon: Icons.autorenew_outlined, label: 'Recurring Expenses', route: Routes.recurring),
    _MoreMenuItem(icon: Icons.ios_share_outlined, label: 'Export & Backup', route: Routes.export),
    _MoreMenuItem(icon: Icons.settings_outlined, label: 'Settings', route: Routes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          final _MoreMenuItem item = _items[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(item.route),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(item.icon, size: 32),
                  const SizedBox(height: 8),
                  Text(item.label, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoreMenuItem {
  const _MoreMenuItem({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}
