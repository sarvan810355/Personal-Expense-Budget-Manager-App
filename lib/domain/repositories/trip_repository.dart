import '../entities/trip.dart';
import '../entities/trip_category_budget.dart';

abstract class TripRepository {
  Stream<List<Trip>> watchAll();
  Future<Trip?> getById(int id);
  Future<int> create(Trip trip);
  Future<void> update(Trip trip);
  Future<void> delete(int id);

  Stream<List<TripCategoryBudget>> watchCategoryBudgetsForTrip(int tripId);
  Future<int> addCategoryBudget(TripCategoryBudget budget);
  Future<void> updateCategoryBudget(TripCategoryBudget budget);
  Future<void> removeCategoryBudget(int id);
}
