import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Persistent bottom-nav scaffold for the 5 primary tabs, with the global
/// "Add Expense" FAB floating above it on every tab (per §22 / §6).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<_TabDestination> _tabs = <_TabDestination>[
    _TabDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    _TabDestination(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Expenses'),
    _TabDestination(icon: Icons.pie_chart_outline, selectedIcon: Icons.pie_chart, label: 'Budget'),
    _TabDestination(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Reports'),
    _TabDestination(icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.addExpense),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: <Widget>[
          for (final _TabDestination tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _TabDestination {
  const _TabDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
