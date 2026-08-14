import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required int id,
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required double totalBudget,
    required DateTime createdAt,
    String? notes,
  }) = _Trip;
}
