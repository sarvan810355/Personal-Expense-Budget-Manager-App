import '../../../domain/entities/expense.dart';

/// Client-side filter applied to the Expense List (§7 of the master
/// prompt). The expense table is small enough for a personal-finance app
/// that filtering the already-loaded stream is simpler and just as fast as
/// building a dynamic SQL `WHERE` clause.
class ExpenseFilter {
  const ExpenseFilter({
    this.start,
    this.end,
    this.categoryId,
    this.paymentMethod,
    this.minAmount,
    this.maxAmount,
  });

  final DateTime? start;
  final DateTime? end;
  final int? categoryId;
  final String? paymentMethod;
  final double? minAmount;
  final double? maxAmount;

  bool get isEmpty =>
      start == null &&
      end == null &&
      categoryId == null &&
      paymentMethod == null &&
      minAmount == null &&
      maxAmount == null;

  List<Expense> apply(List<Expense> expenses) {
    return expenses.where((Expense e) {
      if (start != null && e.date.isBefore(start!)) {
        return false;
      }
      if (end != null && e.date.isAfter(end!)) {
        return false;
      }
      if (categoryId != null && e.categoryId != categoryId) {
        return false;
      }
      if (paymentMethod != null && e.paymentMethod != paymentMethod) {
        return false;
      }
      if (minAmount != null && e.amount < minAmount!) {
        return false;
      }
      if (maxAmount != null && e.amount > maxAmount!) {
        return false;
      }
      return true;
    }).toList();
  }

  ExpenseFilter copyWith({
    DateTime? start,
    DateTime? end,
    int? categoryId,
    String? paymentMethod,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearCategory = false,
    bool clearPaymentMethod = false,
    bool clearAmountRange = false,
  }) {
    return ExpenseFilter(
      start: clearDateRange ? null : (start ?? this.start),
      end: clearDateRange ? null : (end ?? this.end),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      minAmount: clearAmountRange ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmountRange ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

const List<String> kPaymentMethods = <String>[
  'Cash',
  'UPI',
  'Card',
  'Bank',
  'Wallet',
];
