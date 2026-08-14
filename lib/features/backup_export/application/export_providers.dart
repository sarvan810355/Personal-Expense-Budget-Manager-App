import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/income.dart';

const ExportService _exportService = ExportService();

/// Which data set the Export screen should write to CSV.
enum ExportDataType { expenses, income, both }

extension ExportDataTypeLabel on ExportDataType {
  String get label {
    switch (this) {
      case ExportDataType.expenses:
        return 'Expenses';
      case ExportDataType.income:
        return 'Income';
      case ExportDataType.both:
        return 'Both';
    }
  }
}

/// Start of the user-selected export range, defaulting to the start of the
/// current month.
final StateProvider<DateTime> exportStartDateProvider = StateProvider<DateTime>(
  (Ref ref) => AppDateUtils.startOfMonth(DateTime.now()),
);

/// End of the user-selected export range, defaulting to today.
final StateProvider<DateTime> exportEndDateProvider = StateProvider<DateTime>(
  (Ref ref) => AppDateUtils.startOfDay(DateTime.now()),
);

/// Which data set the export button will write, defaulting to both.
final StateProvider<ExportDataType> exportDataTypeProvider =
    StateProvider<ExportDataType>((Ref ref) => ExportDataType.both);

/// Drives the "Export" button: runs the CSV export for the current
/// [exportStartDateProvider]/[exportEndDateProvider]/[exportDataTypeProvider]
/// selection and holds the resulting file list (or error) so the screen can
/// show a confirmation.
class ExportController extends StateNotifier<AsyncValue<List<File>>> {
  ExportController(this._ref) : super(const AsyncValue<List<File>>.data(<File>[]));

  final Ref _ref;

  Future<void> export({
    required ExportDataType dataType,
    required DateTime start,
    required DateTime end,
  }) async {
    state = const AsyncValue<List<File>>.loading();
    state = await AsyncValue.guard(
      () => _run(dataType: dataType, start: AppDateUtils.startOfDay(start), end: AppDateUtils.endOfDay(end)),
    );
  }

  Future<List<File>> _run({
    required ExportDataType dataType,
    required DateTime start,
    required DateTime end,
  }) async {
    final List<Category> categories = await _ref.read(categoryRepositoryProvider).watchAll().first;
    final List<Account> accounts = await _ref.read(accountRepositoryProvider).watchAll().first;
    final Map<int, Category> categoriesById = <int, Category>{
      for (final Category category in categories) category.id: category,
    };
    final Map<int, Account> accountsById = <int, Account>{
      for (final Account account in accounts) account.id: account,
    };

    final String stamp = '${_fileDate(start)}_${_fileDate(end)}';
    final List<File> written = <File>[];

    if (dataType == ExportDataType.expenses || dataType == ExportDataType.both) {
      final List<Expense> expenses =
          await _ref.read(expenseRepositoryProvider).watchByDateRange(start, end).first;
      final String csv = _exportService.expensesToCsv(expenses, categoriesById, accountsById);
      written.add(await _exportService.writeCsvFile('expenses_$stamp.csv', csv));
    }
    if (dataType == ExportDataType.income || dataType == ExportDataType.both) {
      final List<Income> incomes =
          await _ref.read(incomeRepositoryProvider).watchByDateRange(start, end).first;
      final String csv = _exportService.incomesToCsv(incomes, categoriesById, accountsById);
      written.add(await _exportService.writeCsvFile('income_$stamp.csv', csv));
    }
    return written;
  }

  String _fileDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

final StateNotifierProvider<ExportController, AsyncValue<List<File>>> exportControllerProvider =
    StateNotifierProvider<ExportController, AsyncValue<List<File>>>(
  (Ref ref) => ExportController(ref),
);
