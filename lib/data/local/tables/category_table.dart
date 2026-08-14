import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
@TableIndex(name: 'idx_category_type', columns: <Symbol>{#type})
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get type => text()(); // 'expense' | 'income'
  IntColumn get parentCategoryId =>
      integer().nullable().references(Categories, #id)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
