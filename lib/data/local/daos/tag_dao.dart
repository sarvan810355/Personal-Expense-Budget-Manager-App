import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/expense_tag_table.dart';
import '../tables/tag_table.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: <Type>[Tags, ExpenseTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Stream<List<TagRow>> watchAll() => select(tags).watch();

  Future<int> insertTag(TagsCompanion companion) => into(tags).insert(companion);

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((Tags t) => t.id.equals(id))).go();

  Future<void> setTagsForExpense(int expenseId, List<int> tagIds) async {
    await transaction(() async {
      await (delete(expenseTags)
            ..where((ExpenseTags t) => t.expenseId.equals(expenseId)))
          .go();
      for (final int tagId in tagIds) {
        await into(expenseTags).insert(
          ExpenseTagsCompanion.insert(expenseId: expenseId, tagId: tagId),
        );
      }
    });
  }

  Stream<List<TagRow>> watchTagsForExpense(int expenseId) {
    final JoinedSelectStatement<Object?, Object?> query = select(tags).join(
      <Join<Object?, Object?>>[
        innerJoin(expenseTags, expenseTags.tagId.equalsExp(tags.id)),
      ],
    )..where(expenseTags.expenseId.equals(expenseId));

    return query.watch().map(
          (List<TypedResult> rows) =>
              rows.map((TypedResult r) => r.readTable(tags)).toList(),
        );
  }
}
