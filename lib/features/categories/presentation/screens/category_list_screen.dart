import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/category.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Category>> categories =
        ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        data: (List<Category> data) => data.isEmpty
            ? const EmptyStateView(
                icon: Icons.category_outlined,
                title: 'No categories yet',
              )
            : ListView.builder(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  final Category category = data[index];
                  return ListTile(
                    title: Text(category.name),
                    subtitle: Text(category.type.name),
                  );
                },
              ),
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }
}

final StreamProvider<List<Category>> _categoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);
