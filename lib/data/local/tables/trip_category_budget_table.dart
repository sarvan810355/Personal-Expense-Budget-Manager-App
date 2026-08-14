import 'package:drift/drift.dart';

import 'category_table.dart';
import 'trip_table.dart';

@DataClassName('TripCategoryBudgetRow')
class TripCategoryBudgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get allocatedAmount => real()();
}
