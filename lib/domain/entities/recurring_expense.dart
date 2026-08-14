import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_expense.freezed.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

@freezed
class RecurringExpense with _$RecurringExpense {
  const factory RecurringExpense({
    required int id,
    required String title,
    required double amount,
    required int categoryId,
    required int accountId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    required DateTime nextDate,
    required bool active,
    DateTime? endDate,
    String? note,
  }) = _RecurringExpense;
}
