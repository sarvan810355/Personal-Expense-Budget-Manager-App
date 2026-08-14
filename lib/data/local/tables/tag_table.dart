import 'package:drift/drift.dart';

@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}
