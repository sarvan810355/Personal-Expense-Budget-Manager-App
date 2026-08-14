import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_category_budget.freezed.dart';

@freezed
class TripCategoryBudget with _$TripCategoryBudget {
  const factory TripCategoryBudget({
    required int id,
    required int tripId,
    required int categoryId,
    required double allocatedAmount,
  }) = _TripCategoryBudget;
}
