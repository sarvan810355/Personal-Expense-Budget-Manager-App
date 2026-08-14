import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_budget_manager_app/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seeds default expense and income categories on creation', () async {
    final List<CategoryRow> categories = await db.categoryDao.watchAll().first;

    expect(categories, isNotEmpty);
    expect(categories.any((CategoryRow c) => c.name == 'Food'), isTrue);
    expect(categories.any((CategoryRow c) => c.name == 'Transport'), isTrue);
    expect(categories.any((CategoryRow c) => c.name == 'Salary'), isTrue);
  });

  test('Food subcategories resolve parentCategoryId to the Food category', () async {
    final List<CategoryRow> categories = await db.categoryDao.watchAll().first;
    final CategoryRow food = categories.firstWhere((CategoryRow c) => c.name == 'Food');
    final CategoryRow restaurant =
        categories.firstWhere((CategoryRow c) => c.name == 'Restaurant');

    expect(food.parentCategoryId, isNull);
    expect(restaurant.parentCategoryId, food.id);
  });

  test('expense categories are typed "expense" and income categories "income"', () async {
    final List<CategoryRow> categories = await db.categoryDao.watchAll().first;
    final CategoryRow food = categories.firstWhere((CategoryRow c) => c.name == 'Food');
    final CategoryRow salary = categories.firstWhere((CategoryRow c) => c.name == 'Salary');

    expect(food.type, 'expense');
    expect(salary.type, 'income');
  });

  test('seeds exactly one default settings row with expected defaults', () async {
    final AppSettingsRow settings = await db.settingsDao.getSettings();

    expect(settings.id, 1);
    expect(settings.currencyCode, 'USD');
    expect(settings.themeMode, 'system');
    expect(settings.notificationsEnabled, isTrue);
  });

  test('re-running getSettings still returns a single row', () async {
    final List<AppSettingsRow> all =
        await db.select(db.appSettingsTable).get();
    expect(all.length, 1);
  });
}
