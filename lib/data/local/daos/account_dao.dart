import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/account_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: <Type>[Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Stream<List<AccountRow>> watchAll() => select(accounts).watch();

  Future<AccountRow?> getById(int id) {
    return (select(accounts)..where((Accounts t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertAccount(AccountsCompanion companion) =>
      into(accounts).insert(companion);

  Future<bool> updateAccount(AccountsCompanion companion) =>
      update(accounts).replace(companion);

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((Accounts t) => t.id.equals(id))).go();
}
