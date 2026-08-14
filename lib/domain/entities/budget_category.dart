import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_category.freezed.dart';

@freezed
class BudgetCategory with _$BudgetCategory {
  const factory BudgetCategory({
    required int id,
    required int budgetId,
    required int categoryId,
    required double allocatedAmount,
  }) = _BudgetCategory;
}
