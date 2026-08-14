import 'package:drift/drift.dart';

@DataClassName('AccountRow')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash|bank|upi|card|wallet
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}
