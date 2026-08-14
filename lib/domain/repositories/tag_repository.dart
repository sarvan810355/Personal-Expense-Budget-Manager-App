import '../entities/tag.dart';

abstract class TagRepository {
  Stream<List<Tag>> watchAll();
  Future<int> create(Tag tag);
  Future<void> delete(int id);

  Future<void> setTagsForExpense(int expenseId, List<int> tagIds);
  Stream<List<Tag>> watchTagsForExpense(int expenseId);
}
