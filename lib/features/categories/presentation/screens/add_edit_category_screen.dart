import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/icon_map.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../domain/entities/category.dart';

class AddEditCategoryScreen extends ConsumerWidget {
  const AddEditCategoryScreen({super.key, this.categoryId});

  final int? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) {
      return const _CategoryForm();
    }

    final AsyncValue<Category?> existing =
        ref.watch(_categoryByIdProvider(categoryId!));
    return existing.when(
      data: (Category? category) => _CategoryForm(existing: category),
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object e, StackTrace st) =>
          Scaffold(body: ErrorView(message: '$e')),
    );
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({this.existing});

  final Category? existing;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late CategoryType _type = widget.existing?.type ?? CategoryType.expense;
  late String _icon = widget.existing?.icon ?? AppIcons.allNames.first;
  late int _color = widget.existing?.color ?? kColorPalette.first;
  late int? _parentCategoryId = widget.existing?.parentCategoryId;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Category>> allCategories =
        ref.watch(_allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (String? v) =>
                  Validators.requiredText(v, field: 'Name'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CategoryType>(
              segments: const <ButtonSegment<CategoryType>>[
                ButtonSegment<CategoryType>(
                  value: CategoryType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment<CategoryType>(
                  value: CategoryType.income,
                  label: Text('Income'),
                ),
              ],
              selected: <CategoryType>{_type},
              onSelectionChanged: (Set<CategoryType> s) {
                setState(() {
                  _type = s.first;
                  _parentCategoryId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            allCategories.when(
              data: (List<Category> categories) {
                final List<Category> parentOptions = categories
                    .where((Category c) =>
                        c.type == _type &&
                        c.parentCategoryId == null &&
                        c.id != widget.existing?.id)
                    .toList();
                return DropdownButtonFormField<int?>(
                  value: _parentCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Parent category (optional)',
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(child: Text('None (top-level)')),
                    for (final Category c in parentOptions)
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (int? v) => setState(() => _parentCategoryId = v),
                );
              },
              loading: () => const LoadingView(),
              error: (Object e, StackTrace st) => ErrorView(message: '$e'),
            ),
            const SizedBox(height: 24),
            Text('Icon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String name in AppIcons.allNames)
                  _IconChoice(
                    name: name,
                    selected: name == _icon,
                    color: Color(_color),
                    onTap: () => setState(() => _icon = name),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int c in kColorPalette)
                  _ColorChoice(
                    color: c,
                    selected: c == _color,
                    onTap: () => setState(() => _color = c),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Add category'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final Category category = Category(
      id: widget.existing?.id ?? 0,
      name: _nameController.text.trim(),
      icon: _icon,
      color: _color,
      type: _type,
      isDefault: widget.existing?.isDefault ?? false,
      sortOrder: widget.existing?.sortOrder ?? 0,
      parentCategoryId: _parentCategoryId,
    );

    if (_isEditing) {
      await ref.read(categoryRepositoryProvider).update(category);
    } else {
      await ref.read(categoryRepositoryProvider).create(category);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.name,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: selected ? color.withOpacity(0.25) : null,
        child: Icon(
          AppIcons.byName(name),
          color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Color(color),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }
}

final FutureProvider<List<Category>> _allCategoriesProvider =
    FutureProvider<List<Category>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchAll().first,
);

final FutureProviderFamily<Category?, int> _categoryByIdProvider =
    FutureProvider.family<Category?, int>(
  (Ref ref, int id) => ref.watch(categoryRepositoryProvider).getById(id),
);
