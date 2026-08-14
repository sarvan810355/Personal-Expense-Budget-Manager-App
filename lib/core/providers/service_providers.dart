import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/calculation_service.dart';
import '../services/seed_data_service.dart';
import 'repository_providers.dart';

final Provider<CalculationService> calculationServiceProvider =
    Provider<CalculationService>((Ref ref) => const CalculationService());

final Provider<SeedDataService> seedDataServiceProvider =
    Provider<SeedDataService>(
  (Ref ref) => SeedDataService(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    expenseRepository: ref.watch(expenseRepositoryProvider),
    incomeRepository: ref.watch(incomeRepositoryProvider),
    budgetRepository: ref.watch(budgetRepositoryProvider),
    tripRepository: ref.watch(tripRepositoryProvider),
  ),
);
