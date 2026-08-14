import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../data/repositories/recurring_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/repositories/trip_repository.dart';

/// Single [AppDatabase] instance for the app's lifetime. Overridden in
/// tests with an in-memory database (see `test/data/`).
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (Ref ref) {
    final AppDatabase db = AppDatabase();
    ref.onDispose(db.close);
    return db;
  },
);

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
  (Ref ref) => CategoryRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<AccountRepository> accountRepositoryProvider =
    Provider<AccountRepository>(
  (Ref ref) => AccountRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<ExpenseRepository> expenseRepositoryProvider =
    Provider<ExpenseRepository>(
  (Ref ref) => ExpenseRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<IncomeRepository> incomeRepositoryProvider =
    Provider<IncomeRepository>(
  (Ref ref) => IncomeRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<BudgetRepository> budgetRepositoryProvider =
    Provider<BudgetRepository>(
  (Ref ref) => BudgetRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<TripRepository> tripRepositoryProvider =
    Provider<TripRepository>(
  (Ref ref) => TripRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<RecurringRepository> recurringRepositoryProvider =
    Provider<RecurringRepository>(
  (Ref ref) => RecurringRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<TagRepository> tagRepositoryProvider = Provider<TagRepository>(
  (Ref ref) => TagRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
  (Ref ref) => SettingsRepositoryImpl(ref.watch(appDatabaseProvider)),
);
