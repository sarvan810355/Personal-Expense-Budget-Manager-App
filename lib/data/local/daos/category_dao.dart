import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: <Type>[Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<CategoryRow>> watchAll() {
    return (select(categories)
          ..orderBy(
            [(Categories t) => OrderingTerm(expression: t.sortOrder)],
          ))
        .watch();
  }

  Stream<List<CategoryRow>> watchByType(String type) {
    return (select(categories)..where((Categories t) => t.type.equals(type)))
        .watch();
  }

  Future<CategoryRow?> getById(int id) {
    return (select(categories)..where((Categories t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion companion) =>
      into(categories).insert(companion);

  Future<bool> updateCategory(CategoriesCompanion companion) =>
      update(categories).replace(companion);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((Categories t) => t.id.equals(id))).go();
}
