import 'package:drift/drift.dart';

import 'expense_table.dart';
import 'tag_table.dart';

@DataClassName('ExpenseTagRow')
class ExpenseTags extends Table {
  IntColumn get expenseId => integer().references(Expenses, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => <Column>{expenseId, tagId};
}
