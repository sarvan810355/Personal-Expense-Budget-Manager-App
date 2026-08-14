import 'package:drift/drift.dart';

import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_category_budget.dart';
import '../../domain/repositories/trip_repository.dart';
import '../local/app_database.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Trip>> watchAll() =>
      _db.tripDao.watchAll().map((List<TripRow> rows) => rows.map(_toEntity).toList());

  @override
  Future<Trip?> getById(int id) async {
    final TripRow? row = await _db.tripDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(Trip trip) {
    return _db.tripDao.insertTrip(
      TripsCompanion.insert(
        name: trip.name,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
        totalBudget: Value(trip.totalBudget),
        notes: Value(trip.notes),
        createdAt: trip.createdAt,
      ),
    );
  }

  @override
  Future<void> update(Trip trip) {
    return _db.tripDao.updateTrip(
      TripsCompanion(
        id: Value(trip.id),
        name: Value(trip.name),
        destination: Value(trip.destination),
        startDate: Value(trip.startDate),
        endDate: Value(trip.endDate),
        totalBudget: Value(trip.totalBudget),
        notes: Value(trip.notes),
        createdAt: Value(trip.createdAt),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.tripDao.deleteTrip(id);

  @override
  Stream<List<TripCategoryBudget>> watchCategoryBudgetsForTrip(int tripId) {
    return _db.tripDao
        .watchCategoryBudgetsForTrip(tripId)
        .map((List<TripCategoryBudgetRow> rows) => rows.map(_toAllocationEntity).toList());
  }

  @override
  Future<int> addCategoryBudget(TripCategoryBudget budget) {
    return _db.tripDao.insertTripCategoryBudget(
      TripCategoryBudgetsCompanion.insert(
        tripId: budget.tripId,
        categoryId: budget.categoryId,
        allocatedAmount: budget.allocatedAmount,
      ),
    );
  }

  @override
  Future<void> updateCategoryBudget(TripCategoryBudget budget) {
    return _db.tripDao.updateTripCategoryBudget(
      TripCategoryBudgetsCompanion(
        id: Value(budget.id),
        tripId: Value(budget.tripId),
        categoryId: Value(budget.categoryId),
        allocatedAmount: Value(budget.allocatedAmount),
      ),
    );
  }

  @override
  Future<void> removeCategoryBudget(int id) =>
      _db.tripDao.deleteTripCategoryBudget(id);

  Trip _toEntity(TripRow row) => Trip(
        id: row.id,
        name: row.name,
        destination: row.destination,
        startDate: row.startDate,
        endDate: row.endDate,
        totalBudget: row.totalBudget,
        createdAt: row.createdAt,
        notes: row.notes,
      );

  TripCategoryBudget _toAllocationEntity(TripCategoryBudgetRow row) =>
      TripCategoryBudget(
        id: row.id,
        tripId: row.tripId,
        categoryId: row.categoryId,
        allocatedAmount: row.allocatedAmount,
      );
}
