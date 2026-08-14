import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_budget_manager_app/core/services/calculation_service.dart';
import 'package:personal_expense_budget_manager_app/domain/entities/category.dart';
import 'package:personal_expense_budget_manager_app/domain/entities/expense.dart';
import 'package:personal_expense_budget_manager_app/domain/entities/income.dart';

Expense _expense({
  int id = 1,
  double amount = 100,
  int categoryId = 1,
  DateTime? date,
}) {
  final DateTime d = date ?? DateTime(2026, 8, 1);
  return Expense(
    id: id,
    amount: amount,
    title: 'Test expense',
    categoryId: categoryId,
    accountId: 1,
    date: d,
    createdAt: d,
    updatedAt: d,
  );
}

Income _income({int id = 1, double amount = 100, DateTime? date}) {
  final DateTime d = date ?? DateTime(2026, 8, 1);
  return Income(
    id: id,
    amount: amount,
    source: IncomeSource.salary,
    accountId: 1,
    date: d,
    createdAt: d,
  );
}

Category _category(int id, String name) => Category(
      id: id,
      name: name,
      icon: 'category',
      color: 0xFF000000,
      type: CategoryType.expense,
      isDefault: false,
      sortOrder: 0,
    );

void main() {
  const CalculationService service = CalculationService();

  group('totalExpense', () {
    test('empty list returns 0', () {
      expect(service.totalExpense(<Expense>[]), 0);
    });

    test('single item returns its amount', () {
      expect(service.totalExpense(<Expense>[_expense(amount: 42.5)]), 42.5);
    });

    test('multiple items returns the sum', () {
      final List<Expense> expenses = <Expense>[
        _expense(id: 1, amount: 10),
        _expense(id: 2, amount: 20.25),
        _expense(id: 3, amount: 5.75),
      ];
      expect(service.totalExpense(expenses), 36);
    });
  });

  group('totalIncome', () {
    test('empty list returns 0', () {
      expect(service.totalIncome(<Income>[]), 0);
    });

    test('single item returns its amount', () {
      expect(service.totalIncome(<Income>[_income(amount: 500)]), 500);
    });

    test('multiple items returns the sum', () {
      final List<Income> incomes = <Income>[
        _income(id: 1, amount: 1000),
        _income(id: 2, amount: 250.5),
      ];
      expect(service.totalIncome(incomes), 1250.5);
    });
  });

  test('savings is income minus expense', () {
    expect(service.savings(1000, 400), 600);
    expect(service.savings(0, 400), -400);
  });

  group('budgetRemaining / budgetPercentUsed', () {
    test('remaining and percent for a partially spent budget', () {
      expect(service.budgetRemaining(1000, 400), 600);
      expect(service.budgetPercentUsed(1000, 400), 40);
    });

    test('percent used is 0 when budget amount is 0', () {
      expect(service.budgetPercentUsed(0, 400), 0);
    });

    test('percent used can exceed 100 when overspent', () {
      expect(service.budgetPercentUsed(100, 150), 150);
    });
  });

  test('tripRemaining is budget minus spent', () {
    expect(service.tripRemaining(5000, 3200), 1800);
  });

  group('averageDailyExpense', () {
    test('returns 0 when days is 0', () {
      expect(service.averageDailyExpense(500, 0), 0);
    });

    test('divides total by day count', () {
      expect(service.averageDailyExpense(500, 5), 100);
    });
  });

  group('dayWiseBreakdown', () {
    test('empty list returns empty map', () {
      expect(service.dayWiseBreakdown(<Expense>[]), isEmpty);
    });

    test('single expense maps to its day', () {
      final DateTime date = DateTime(2026, 8, 3);
      final Map<DateTime, double> result =
          service.dayWiseBreakdown(<Expense>[_expense(amount: 50, date: date)]);
      expect(result, <DateTime, double>{DateTime(2026, 8, 3): 50});
    });

    test('multiple expenses on the same day are summed, different days kept separate', () {
      final List<Expense> expenses = <Expense>[
        _expense(id: 1, amount: 10, date: DateTime(2026, 8, 1, 9)),
        _expense(id: 2, amount: 20, date: DateTime(2026, 8, 1, 18)),
        _expense(id: 3, amount: 5, date: DateTime(2026, 8, 2)),
      ];
      final Map<DateTime, double> result = service.dayWiseBreakdown(expenses);
      expect(result[DateTime(2026, 8, 1)], 30);
      expect(result[DateTime(2026, 8, 2)], 5);
      expect(result.length, 2);
    });
  });

  group('categoryBreakdown', () {
    test('empty list returns empty map', () {
      expect(service.categoryBreakdown(<Expense>[], <int, Category>{}), isEmpty);
    });

    test('single expense maps to its category', () {
      final Category food = _category(1, 'Food');
      final Map<Category, double> result = service.categoryBreakdown(
        <Expense>[_expense(categoryId: 1, amount: 75)],
        <int, Category>{1: food},
      );
      expect(result, <Category, double>{food: 75});
    });

    test('multiple expenses are summed per category, unknown categories skipped', () {
      final Category food = _category(1, 'Food');
      final Category transport = _category(2, 'Transport');
      final List<Expense> expenses = <Expense>[
        _expense(id: 1, categoryId: 1, amount: 20),
        _expense(id: 2, categoryId: 1, amount: 30),
        _expense(id: 3, categoryId: 2, amount: 15),
        _expense(id: 4, categoryId: 99, amount: 1000), // no matching category
      ];
      final Map<Category, double> result = service.categoryBreakdown(
        expenses,
        <int, Category>{1: food, 2: transport},
      );
      expect(result[food], 50);
      expect(result[transport], 15);
      expect(result.length, 2);
    });
  });

  group('monthlyComparison', () {
    test('empty list returns zeroed months', () {
      final Map<DateTime, double> result = service.monthlyComparison(
        <Expense>[],
        3,
        anchor: DateTime(2026, 8, 15),
      );
      expect(result.length, 3);
      expect(result.values.every((double v) => v == 0), isTrue);
      expect(result.keys, contains(DateTime(2026, 8)));
      expect(result.keys, contains(DateTime(2026, 6)));
    });

    test('single expense lands in its month', () {
      final Map<DateTime, double> result = service.monthlyComparison(
        <Expense>[_expense(amount: 100, date: DateTime(2026, 7, 10))],
        2,
        anchor: DateTime(2026, 8, 15),
      );
      expect(result[DateTime(2026, 7)], 100);
      expect(result[DateTime(2026, 8)], 0);
    });

    test('multiple expenses across months are summed per month, out-of-range dropped', () {
      final List<Expense> expenses = <Expense>[
        _expense(id: 1, amount: 100, date: DateTime(2026, 6, 5)),
        _expense(id: 2, amount: 50, date: DateTime(2026, 6, 20)),
        _expense(id: 3, amount: 75, date: DateTime(2026, 8, 1)),
        _expense(id: 4, amount: 999, date: DateTime(2026, 1, 1)), // out of range
      ];
      final Map<DateTime, double> result = service.monthlyComparison(
        expenses,
        3,
        anchor: DateTime(2026, 8, 15),
      );
      expect(result[DateTime(2026, 6)], 150);
      expect(result[DateTime(2026, 7)], 0);
      expect(result[DateTime(2026, 8)], 75);
      expect(result.length, 3);
    });
  });

  group('monthlyIncomeComparison', () {
    test('empty list returns zeroed months', () {
      final Map<DateTime, double> result = service.monthlyIncomeComparison(
        <Income>[],
        3,
        anchor: DateTime(2026, 8, 15),
      );
      expect(result.length, 3);
      expect(result.values.every((double v) => v == 0), isTrue);
      expect(result.keys, contains(DateTime(2026, 8)));
      expect(result.keys, contains(DateTime(2026, 6)));
    });

    test('single income lands in its month', () {
      final Map<DateTime, double> result = service.monthlyIncomeComparison(
        <Income>[_income(amount: 1000, date: DateTime(2026, 7, 10))],
        2,
        anchor: DateTime(2026, 8, 15),
      );
      expect(result[DateTime(2026, 7)], 1000);
      expect(result[DateTime(2026, 8)], 0);
    });

    test('multiple incomes across months are summed per month, out-of-range dropped', () {
      final List<Income> incomes = <Income>[
        _income(id: 1, amount: 1000, date: DateTime(2026, 6, 5)),
        _income(id: 2, amount: 500, date: DateTime(2026, 6, 20)),
        _income(id: 3, amount: 750, date: DateTime(2026, 8, 1)),
        _income(id: 4, amount: 999, date: DateTime(2026, 1, 1)), // out of range
      ];
      final Map<DateTime, double> result = service.monthlyIncomeComparison(
        incomes,
        3,
        anchor: DateTime(2026, 8, 15),
      );
      expect(result[DateTime(2026, 6)], 1500);
      expect(result[DateTime(2026, 7)], 0);
      expect(result[DateTime(2026, 8)], 750);
      expect(result.length, 3);
    });
  });
}
