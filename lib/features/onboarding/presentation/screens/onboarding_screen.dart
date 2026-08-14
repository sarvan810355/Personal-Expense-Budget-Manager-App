import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/empty_state_view.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyStateView(
        icon: Icons.waving_hand_outlined,
        title: 'Welcome to Expense Manager',
        message: 'Track expenses, set budgets, and plan trips — all offline.',
        actionLabel: 'Get started',
        onAction: () => context.go(Routes.dashboard),
      ),
    );
  }
}
