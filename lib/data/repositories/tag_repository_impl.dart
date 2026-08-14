import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../local/app_database.dart';

class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Tag>> watchAll() =>
      _db.tagDao.watchAll().map((List<TagRow> rows) => rows.map(_toEntity).toList());

  @override
  Future<int> create(Tag tag) {
    return _db.tagDao.insertTag(TagsCompanion.insert(name: tag.name));
  }

  @override
  Future<void> delete(int id) => _db.tagDao.deleteTag(id);

  @override
  Future<void> setTagsForExpense(int expenseId, List<int> tagIds) =>
      _db.tagDao.setTagsForExpense(expenseId, tagIds);

  @override
  Stream<List<Tag>> watchTagsForExpense(int expenseId) {
    return _db.tagDao
        .watchTagsForExpense(expenseId)
        .map((List<TagRow> rows) => rows.map(_toEntity).toList());
  }

  Tag _toEntity(TagRow row) => Tag(id: row.id, name: row.name);
}
