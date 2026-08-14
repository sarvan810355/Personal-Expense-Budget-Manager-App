import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TextField(
          autofocus: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search expenses, income...',
          ),
        ),
      ),
      body: const EmptyStateView(
        icon: Icons.search,
        title: 'Global search coming in Phase 2',
      ),
    );
  }
}
