import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/income.dart';
import '../utils/date_utils.dart';

/// Builds CSV exports of expenses/income and writes them to the app's
/// documents directory. Excel/PDF export need packages that aren't in
/// `pubspec.yaml` yet, so they stay out of scope here (see
/// `export_backup_screen.dart`).
class ExportService {
  const ExportService();

  static const List<String> expenseHeader = <String>[
    'Date',
    'Title',
    'Category',
    'Account',
    'Amount',
    'Payment Method',
    'Location',
    'Note',
  ];

  static const List<String> incomeHeader = <String>[
    'Date',
    'Source',
    'Category',
    'Account',
    'Amount',
    'Note',
  ];

  /// Renders [expenses] as CSV text, resolving category/account names from
  /// [categoriesById]/[accountsById] (falling back to an empty cell if the
  /// id has no match).
  String expensesToCsv(
    List<Expense> expenses,
    Map<int, Category> categoriesById,
    Map<int, Account> accountsById,
  ) {
    final List<List<String>> rows = <List<String>>[
      expenseHeader,
      for (final Expense expense in expenses)
        <String>[
          AppDateUtils.formatShort(expense.date),
          expense.title,
          categoriesById[expense.categoryId]?.name ?? '',
          accountsById[expense.accountId]?.name ?? '',
          expense.amount.toStringAsFixed(2),
          expense.paymentMethod ?? '',
          expense.location ?? '',
          expense.note ?? '',
        ],
    ];
    return _toCsvString(rows);
  }

  /// Renders [incomes] as CSV text, resolving category/account names from
  /// [categoriesById]/[accountsById] (falling back to an empty cell if the
  /// id has no match).
  String incomesToCsv(
    List<Income> incomes,
    Map<int, Category> categoriesById,
    Map<int, Account> accountsById,
  ) {
    final List<List<String>> rows = <List<String>>[
      incomeHeader,
      for (final Income income in incomes)
        <String>[
          AppDateUtils.formatShort(income.date),
          income.source.name,
          income.categoryId == null ? '' : (categoriesById[income.categoryId]?.name ?? ''),
          accountsById[income.accountId]?.name ?? '',
          income.amount.toStringAsFixed(2),
          income.note ?? '',
        ],
    ];
    return _toCsvString(rows);
  }

  String _toCsvString(List<List<String>> rows) =>
      rows.map((List<String> row) => row.map(_escapeField).join(',')).join('\r\n');

  /// Quotes a field per RFC 4180 when it contains a comma, quote, or
  /// newline; doubles any embedded quotes.
  String _escapeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Writes [contents] to [filename] inside the app's documents directory
  /// and returns the written file.
  Future<File> writeCsvFile(String filename, String contents) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, filename));
    return file.writeAsString(contents);
  }
}
