/// Route path constants (see ARCHITECTURE.md §6 Navigation Map). Screens
/// and `context.go`/`context.push` calls should reference these instead of
/// hardcoding path strings.
class Routes {
  const Routes._();

  // Bottom-nav tabs
  static const String dashboard = '/dashboard';
  static const String expenses = '/expenses';
  static const String expenseDetail = '/expenses/:id';
  static const String budgets = '/budgets';
  static const String budgetDetail = '/budgets/:id';
  static const String reports = '/reports';
  static const String more = '/more';

  // Global (reached via FAB / app bar icons, outside the bottom-nav shell)
  static const String addExpense = '/add-expense';
  static const String addIncome = '/add-income';
  static const String calendar = '/calendar';
  static const String search = '/search';
  static const String onboarding = '/onboarding';
  static const String receiptViewer = '/expenses/:id/receipt';

  // Reached from the More menu
  static const String income = '/income';
  static const String trips = '/trips';
  static const String tripDetail = '/trips/:id';
  static const String tripCreate = '/trips/create';
  static const String tripAddExpense = '/trips/:id/add-expense';
  static const String categories = '/categories';
  static const String categoryAdd = '/categories/add';
  static const String accounts = '/accounts';
  static const String accountAdd = '/accounts/add';
  static const String recurring = '/recurring';
  static const String recurringAdd = '/recurring/add';
  static const String export = '/export';
  static const String settings = '/settings';
  static const String budgetCreate = '/budgets/create';

  static String expenseDetailPath(int id) => '/expenses/$id';
  static String receiptViewerPath(int id) => '/expenses/$id/receipt';
  static String budgetDetailPath(int id) => '/budgets/$id';
  static String tripDetailPath(int id) => '/trips/$id';
  static String tripAddExpensePath(int id) => '/trips/$id/add-expense';
}
