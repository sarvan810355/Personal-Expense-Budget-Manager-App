import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_budget_manager_app/app/theme/theme_controller.dart';
import 'package:personal_expense_budget_manager_app/core/providers/repository_providers.dart';
import 'package:personal_expense_budget_manager_app/data/local/app_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('defaults to ThemeMode.system, matching the seeded settings row', () async {
    // Wait for the controller's async _load() to complete.
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('setThemeMode updates state and persists to the settings table', () async {
    await container
        .read(themeModeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);

    final AppSettingsRow settings = await db.settingsDao.getSettings();
    expect(settings.themeMode, 'dark');
  });
}
