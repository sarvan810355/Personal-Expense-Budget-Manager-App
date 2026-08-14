import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';

enum BudgetPeriodType { weekly, monthly, custom }

@freezed
class Budget with _$Budget {
  const factory Budget({
    required int id,
    required String name,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    required double totalAmount,
    required List<int> alertThresholds,
    required DateTime createdAt,
  }) = _Budget;
}
