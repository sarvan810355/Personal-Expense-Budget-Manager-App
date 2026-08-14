import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/screens/account_list_screen.dart';
import '../../features/accounts/presentation/screens/add_edit_account_screen.dart';
import '../../features/backup_export/presentation/screens/export_backup_screen.dart';
import '../../features/budgets/presentation/screens/budget_detail_screen.dart';
import '../../features/budgets/presentation/screens/budget_list_screen.dart';
import '../../features/budgets/presentation/screens/create_edit_budget_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/categories/presentation/screens/add_edit_category_screen.dart';
import '../../features/categories/presentation/screens/category_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/expenses/presentation/screens/add_edit_expense_screen.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/expenses/presentation/screens/expense_list_screen.dart';
import '../../features/expenses/presentation/screens/receipt_viewer_screen.dart';
import '../../features/income/presentation/screens/add_edit_income_screen.dart';
import '../../features/income/presentation/screens/income_list_screen.dart';
import '../../features/more/presentation/screens/more_menu_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/recurring/presentation/screens/add_edit_recurring_screen.dart';
import '../../features/recurring/presentation/screens/recurring_list_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/trips/presentation/screens/add_trip_expense_screen.dart';
import '../../features/trips/presentation/screens/create_edit_trip_screen.dart';
import '../../features/trips/presentation/screens/trip_detail_screen.dart';
import '../../features/trips/presentation/screens/trip_list_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: Routes.dashboard,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            AppShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: Routes.dashboard,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: Routes.expenses,
              builder: (_, __) => const ExpenseListScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: ':id',
                  builder: (_, GoRouterState state) => ExpenseDetailScreen(
                    expenseId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: Routes.budgets,
              builder: (_, __) => const BudgetListScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: ':id',
                  builder: (_, GoRouterState state) => BudgetDetailScreen(
                    budgetId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: Routes.reports,
              builder: (_, __) => const ReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: Routes.more,
              builder: (_, __) => const MoreMenuScreen(),
            ),
          ]),
        ],
      ),

      // Global / full-screen routes reached outside the bottom-nav shell.
      GoRoute(
        path: Routes.addExpense,
        builder: (_, __) => const AddEditExpenseScreen(),
      ),
      GoRoute(
        path: Routes.addIncome,
        builder: (_, __) => const AddEditIncomeScreen(),
      ),
      GoRoute(
        path: Routes.calendar,
        builder: (_, __) => const CalendarScreen(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.receiptViewer,
        builder: (_, GoRouterState state) => ReceiptViewerScreen(
          expenseId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Reached from the More menu.
      GoRoute(
        path: Routes.income,
        builder: (_, __) => const IncomeListScreen(),
      ),
      GoRoute(
        path: Routes.trips,
        builder: (_, __) => const TripListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateEditTripScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, GoRouterState state) => TripDetailScreen(
              tripId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: ':id/add-expense',
            builder: (_, GoRouterState state) => AddTripExpenseScreen(
              tripId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.categories,
        builder: (_, __) => const CategoryListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'add',
            builder: (_, __) => const AddEditCategoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.accounts,
        builder: (_, __) => const AccountListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'add',
            builder: (_, __) => const AddEditAccountScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.recurring,
        builder: (_, __) => const RecurringListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'add',
            builder: (_, __) => const AddEditRecurringScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.export,
        builder: (_, __) => const ExportBackupScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.budgetCreate,
        builder: (_, __) => const CreateEditBudgetScreen(),
      ),
    ],
  );
});
