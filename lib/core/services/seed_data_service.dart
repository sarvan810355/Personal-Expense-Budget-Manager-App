import '../../domain/entities/account.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/income.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/repositories/trip_repository.dart';

/// Populates the database with a small set of realistic demo records
/// (accounts, expenses, income, a budget, a trip) so a first-time user can
/// explore the app without entering data manually.
///
/// Never invoked automatically — it is only ever triggered by the explicit
/// "Load demo data" toggle on the Settings screen (Phase 2+), which keeps
/// production installs free of synthetic data.
class SeedDataService {
  const SeedDataService({
    required this.categoryRepository,
    required this.accountRepository,
    required this.expenseRepository,
    required this.incomeRepository,
    required this.budgetRepository,
    required this.tripRepository,
  });

  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  final BudgetRepository budgetRepository;
  final TripRepository tripRepository;

  Future<void> loadDemoData() async {
    final DateTime now = DateTime.now();

    final int cashAccountId = await accountRepository.create(
      Account(
        id: 0,
        name: 'Cash',
        type: AccountType.cash,
        balance: 5000,
        icon: 'wallet',
        color: 0xFF2E7D5B,
        isActive: true,
        createdAt: now,
      ),
    );
    final int bankAccountId = await accountRepository.create(
      Account(
        id: 0,
        name: 'Bank Account',
        type: AccountType.bank,
        balance: 25000,
        icon: 'bank',
        color: 0xFF1976D2,
        isActive: true,
        createdAt: now,
      ),
    );

    final List<Category> expenseCategories =
        await categoryRepository.watchByType(CategoryType.expense).first;
    final List<Category> incomeCategories =
        await categoryRepository.watchByType(CategoryType.income).first;

    if (expenseCategories.isNotEmpty) {
      final int foodCategoryId = expenseCategories
          .firstWhere(
            (Category c) => c.name == 'Food',
            orElse: () => expenseCategories.first,
          )
          .id;
      final int transportCategoryId = expenseCategories
          .firstWhere(
            (Category c) => c.name == 'Transport',
            orElse: () => expenseCategories.first,
          )
          .id;

      for (int i = 0; i < 5; i++) {
        final DateTime date = now.subtract(Duration(days: i));
        await expenseRepository.create(
          Expense(
            id: 0,
            amount: 250.0 + (i * 35),
            title: i.isEven ? 'Groceries' : 'Cab ride',
            categoryId: i.isEven ? foodCategoryId : transportCategoryId,
            accountId: i.isEven ? cashAccountId : bankAccountId,
            date: date,
            createdAt: date,
            updatedAt: date,
          ),
        );
      }
    }

    if (incomeCategories.isNotEmpty) {
      final int salaryCategoryId = incomeCategories
          .firstWhere(
            (Category c) => c.name == 'Salary',
            orElse: () => incomeCategories.first,
          )
          .id;
      await incomeRepository.create(
        Income(
          id: 0,
          amount: 60000,
          source: IncomeSource.salary,
          accountId: bankAccountId,
          date: DateTime(now.year, now.month, 1),
          createdAt: now,
          categoryId: salaryCategoryId,
        ),
      );
    }

    await budgetRepository.create(
      Budget(
        id: 0,
        name: '${_monthName(now.month)} ${now.year} Budget',
        periodType: BudgetPeriodType.monthly,
        startDate: DateTime(now.year, now.month),
        endDate: DateTime(now.year, now.month + 1, 0),
        totalAmount: 20000,
        alertThresholds: const <int>[80, 90, 100],
        createdAt: now,
      ),
    );

    await tripRepository.create(
      Trip(
        id: 0,
        name: 'Weekend Getaway',
        destination: 'Goa',
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 17)),
        totalBudget: 15000,
        createdAt: now,
        notes: 'Demo trip seeded for exploring the Trips feature.',
      ),
    );
  }

  static String _monthName(int month) {
    const List<String> months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}
