import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class AddEditCategoryScreen extends StatelessWidget {
  const AddEditCategoryScreen({super.key, this.categoryId});

  final int? categoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryId == null ? 'Add Category' : 'Edit Category')),
      body: const EmptyStateView(
        icon: Icons.category_outlined,
        title: 'Category form coming in Phase 2',
      ),
    );
  }
}
