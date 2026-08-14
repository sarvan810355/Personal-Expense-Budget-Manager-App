import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/category_icon_avatar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/category.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> categories =
        ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.categoryAdd),
        child: const Icon(Icons.add),
      ),
      body: categories.when(
        data: (List<Category> data) => TabBarView(
          controller: _tabController,
          children: <Widget>[
            _CategoryTab(categories: _byType(data, CategoryType.expense)),
            _CategoryTab(categories: _byType(data, CategoryType.income)),
          ],
        ),
        loading: () => const LoadingView(),
        error: (Object e, StackTrace st) => ErrorView(message: '$e'),
      ),
    );
  }

  List<Category> _byType(List<Category> all, CategoryType type) =>
      all.where((Category c) => c.type == type).toList()
        ..sort((Category a, Category b) => a.sortOrder.compareTo(b.sortOrder));
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return const EmptyStateView(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        message: 'Tap + to add your first category.',
      );
    }

    final Map<int, Category> byId = <int, Category>{
      for (final Category c in categories) c.id: c,
    };
    final List<Category> topLevel =
        categories.where((Category c) => c.parentCategoryId == null).toList();
    final List<Category> orphanSubs = categories
        .where((Category c) =>
            c.parentCategoryId != null && !byId.containsKey(c.parentCategoryId))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        for (final Category parent in topLevel) ...<Widget>[
          _CategoryTile(category: parent),
          for (final Category child in categories.where(
            (Category c) => c.parentCategoryId == parent.id,
          ))
            _CategoryTile(category: child, indent: true),
        ],
        for (final Category orphan in orphanSubs) _CategoryTile(category: orphan),
      ],
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category, this.indent = false});

  final Category category;
  final bool indent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent ? 48 : 16, right: 8),
      leading: CategoryIconAvatar(iconName: category.icon, color: category.color),
      title: Text(category.name),
      subtitle: category.isDefault ? const Text('Default category') : null,
      trailing: PopupMenuButton<String>(
        onSelected: (String action) async {
          if (action == 'edit') {
            context.push(Routes.categoryEditPath(category.id));
          } else if (action == 'delete') {
            await _confirmDelete(context, ref);
          }
        },
        itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
          PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}"? Expenses already using it will keep '
          'their record but the category will no longer be selectable.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(categoryRepositoryProvider).delete(category.id);
    }
  }
}

final StreamProvider<List<Category>> _categoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);
