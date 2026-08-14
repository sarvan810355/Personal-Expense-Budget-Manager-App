import 'package:drift/drift.dart';

import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../local/app_database.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Account>> watchAll() =>
      _db.accountDao.watchAll().map((List<AccountRow> rows) => rows.map(_toEntity).toList());

  @override
  Future<Account?> getById(int id) async {
    final AccountRow? row = await _db.accountDao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create(Account account) {
    return _db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: account.name,
        type: _typeToString(account.type),
        balance: Value(account.balance),
        icon: account.icon,
        color: account.color,
        isActive: Value(account.isActive),
        createdAt: account.createdAt,
      ),
    );
  }

  @override
  Future<void> update(Account account) {
    return _db.accountDao.updateAccount(
      AccountsCompanion(
        id: Value(account.id),
        name: Value(account.name),
        type: Value(_typeToString(account.type)),
        balance: Value(account.balance),
        icon: Value(account.icon),
        color: Value(account.color),
        isActive: Value(account.isActive),
        createdAt: Value(account.createdAt),
      ),
    );
  }

  @override
  Future<void> delete(int id) => _db.accountDao.deleteAccount(id);

  Account _toEntity(AccountRow row) => Account(
        id: row.id,
        name: row.name,
        type: AccountType.values.firstWhere(
          (AccountType t) => t.name == row.type,
          orElse: () => AccountType.cash,
        ),
        balance: row.balance,
        icon: row.icon,
        color: row.color,
        isActive: row.isActive,
        createdAt: row.createdAt,
      );

  String _typeToString(AccountType type) => type.name;
}
