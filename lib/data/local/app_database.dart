import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/default_categories.dart';
import 'daos/account_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/income_dao.dart';
import 'daos/recurring_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/trip_dao.dart';
import 'tables/account_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/budget_category_table.dart';
import 'tables/budget_table.dart';
import 'tables/category_table.dart';
import 'tables/expense_table.dart';
import 'tables/expense_tag_table.dart';
import 'tables/income_table.dart';
import 'tables/recurring_expense_table.dart';
import 'tables/tag_table.dart';
import 'tables/trip_category_budget_table.dart';
import 'tables/trip_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Categories,
    Accounts,
    Expenses,
    Incomes,
    Tags,
    ExpenseTags,
    Budgets,
    BudgetCategories,
    Trips,
    TripCategoryBudgets,
    RecurringExpenses,
    AppSettingsTable,
  ],
  daos: <Type>[
    CategoryDao,
    AccountDao,
    ExpenseDao,
    IncomeDao,
    BudgetDao,
    TripDao,
    RecurringDao,
    SettingsDao,
    TagDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDefaultCategories();
          await _seedDefaultSettings();
        },
      );

  /// Inserts §6's default category list, parents first so subcategories
  /// (e.g. Food → Restaurant/Groceries/Cafe) can resolve `parentCategoryId`.
  Future<void> _seedDefaultCategories() async {
    final Map<String, int> idByName = <String, int>{};
    final List<DefaultCategorySeed> parents =
        kAllDefaultCategories.where((DefaultCategorySeed c) => c.parentName == null).toList();
    final List<DefaultCategorySeed> children =
        kAllDefaultCategories.where((DefaultCategorySeed c) => c.parentName != null).toList();

    for (final DefaultCategorySeed seed in parents) {
      final int id = await into(categories).insert(
        CategoriesCompanion.insert(
          name: seed.name,
          icon: seed.icon,
          color: seed.color,
          type: seed.type,
          isDefault: const Value(true),
          sortOrder: Value(seed.sortOrder),
        ),
      );
      idByName[seed.name] = id;
    }

    for (final DefaultCategorySeed seed in children) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: seed.name,
          icon: seed.icon,
          color: seed.color,
          type: seed.type,
          isDefault: const Value(true),
          sortOrder: Value(seed.sortOrder),
          parentCategoryId: Value(idByName[seed.parentName]),
        ),
      );
    }
  }

  Future<void> _seedDefaultSettings() async {
    await into(appSettingsTable).insert(
      const AppSettingsTableCompanion.insert(),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'expense_manager.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
