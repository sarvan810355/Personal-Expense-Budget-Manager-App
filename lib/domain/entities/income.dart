import 'package:freezed_annotation/freezed_annotation.dart';

part 'income.freezed.dart';

enum IncomeSource { salary, business, investment, freelance, gift, other }

@freezed
class Income with _$Income {
  const factory Income({
    required int id,
    required double amount,
    required IncomeSource source,
    required int accountId,
    required DateTime date,
    required DateTime createdAt,
    int? categoryId,
    String? note,
  }) = _Income;
}
