import '../entities/account.dart';

abstract class AccountRepository {
  Stream<List<Account>> watchAll();
  Future<Account?> getById(int id);
  Future<int> create(Account account);
  Future<void> update(Account account);
  Future<void> delete(int id);
}
