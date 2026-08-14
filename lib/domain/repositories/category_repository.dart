import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAll();
  Stream<List<Category>> watchByType(CategoryType type);
  Future<Category?> getById(int id);
  Future<int> create(Category category);
  Future<void> update(Category category);
  Future<void> delete(int id);
}
