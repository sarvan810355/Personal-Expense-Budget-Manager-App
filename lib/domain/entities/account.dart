import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

enum AccountType { cash, bank, upi, card, wallet }

@freezed
class Account with _$Account {
  const factory Account({
    required int id,
    required String name,
    required AccountType type,
    required double balance,
    required String icon,
    required int color,
    required bool isActive,
    required DateTime createdAt,
  }) = _Account;
}
