import 'package:drift/drift.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../local/app_database.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() =>
      _db.categoryDao.watchAll().map(_mapRows);

  @override
  Stream<List<Category>> watchByType(CategoryType type) =>
      _db.categoryDao.watchByType(_typeToString(type)).map(_mapRows);

  @override
  Future<Category?> getById(int id) async {
    final CategoryRow? row = await _db.categoryDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(Category category) {
    return _db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: category.name,
        icon: category.icon,
        color: category.color,
        type: _typeToString(category.type),
        isDefault: Value(category.isDefault),
        sortOrder: Value(category.sortOrder),
        parentCategoryId: Value(category.parentCategoryId),
      ),
    );
  }

  @override
  Future<void> update(Category category) {
    return _db.categoryDao.updateCategory(
      CategoriesCompanion(
        id: Value(category.id),
        name: Value(category.name),
        icon: Value(category.icon),
        color: Value(category.color),
        type: Value(_typeToString(category.type)),
        isDefault: Value(category.isDefault),
        sortOrder: Value(category.sortOrder),
        parentCategoryId: Value(category.parentCategoryId),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.categoryDao.deleteCategory(id);

  List<Category> _mapRows(List<CategoryRow> rows) =>
      rows.map(_toEntity).toList();

  Category _toEntity(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        icon: row.icon,
        color: row.color,
        type: row.type == 'income' ? CategoryType.income : CategoryType.expense,
        isDefault: row.isDefault,
        sortOrder: row.sortOrder,
        parentCategoryId: row.parentCategoryId,
      );

  String _typeToString(CategoryType type) =>
      type == CategoryType.income ? 'income' : 'expense';
}
