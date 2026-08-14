import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_budget_manager_app/app/app.dart';
import 'package:personal_expense_budget_manager_app/core/providers/repository_providers.dart';
import 'package:personal_expense_budget_manager_app/data/local/app_database.dart';

void main() {
  testWidgets('launches to the Dashboard shell and navigates all 5 tabs',
      (WidgetTester tester) async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
        child: const ExpenseManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);

    for (final String label in <String>['Expenses', 'Budget', 'Reports', 'More']) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
