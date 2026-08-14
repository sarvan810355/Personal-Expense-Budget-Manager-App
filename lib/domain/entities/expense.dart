import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    required int id,
    required double amount,
    required String title,
    required int categoryId,
    required int accountId,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? tripId,
    String? time,
    String? note,
    String? paymentMethod,
    String? location,
    String? receiptPath,
  }) = _Expense;
}
