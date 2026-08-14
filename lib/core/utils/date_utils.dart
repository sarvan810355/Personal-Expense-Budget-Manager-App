import 'package:intl/intl.dart';

/// Date helpers shared across screens/services so formatting stays
/// consistent (calendar, expense list, reports, trip day-wise view).
class AppDateUtils {
  const AppDateUtils._();

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int daysBetween(DateTime start, DateTime end) {
    final DateTime a = startOfDay(start);
    final DateTime b = startOfDay(end);
    return b.difference(a).inDays + 1;
  }

  static String formatShort(DateTime date) => DateFormat.yMMMd().format(date);

  static String formatDay(DateTime date) => DateFormat.MMMd().format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat.yMMMM().format(date);
}
