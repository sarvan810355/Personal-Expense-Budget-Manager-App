import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/trip_category_budget_table.dart';
import '../tables/trip_table.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: <Type>[Trips, TripCategoryBudgets])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.db);

  Stream<List<TripRow>> watchAll() {
    return (select(trips)
          ..orderBy(
            [(Trips t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)],
          ))
        .watch();
  }

  Future<TripRow?> getById(int id) {
    return (select(trips)..where((Trips t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTrip(TripsCompanion companion) =>
      into(trips).insert(companion);

  Future<bool> updateTrip(TripsCompanion companion) =>
      update(trips).replace(companion);

  Future<int> deleteTrip(int id) =>
      (delete(trips)..where((Trips t) => t.id.equals(id))).go();

  Stream<List<TripCategoryBudgetRow>> watchCategoryBudgetsForTrip(int tripId) {
    return (select(tripCategoryBudgets)
          ..where((TripCategoryBudgets t) => t.tripId.equals(tripId)))
        .watch();
  }

  Future<int> insertTripCategoryBudget(TripCategoryBudgetsCompanion companion) =>
      into(tripCategoryBudgets).insert(companion);

  Future<bool> updateTripCategoryBudget(TripCategoryBudgetsCompanion companion) =>
      update(tripCategoryBudgets).replace(companion);

  Future<int> deleteTripCategoryBudget(int id) => (delete(tripCategoryBudgets)
        ..where((TripCategoryBudgets t) => t.id.equals(id)))
      .go();
}
