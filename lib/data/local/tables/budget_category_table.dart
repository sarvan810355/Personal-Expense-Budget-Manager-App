import 'package:drift/drift.dart';

import 'budget_table.dart';
import 'category_table.dart';

@DataClassName('BudgetCategoryRow')
class BudgetCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId => integer().references(Budgets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get allocatedAmount => real()();
}
