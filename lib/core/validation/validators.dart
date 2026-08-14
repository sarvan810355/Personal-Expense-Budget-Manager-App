/// Form validators shared by the Add/Edit screens introduced in Phase 2+.
/// Kept in Phase 1 so form widgets can depend on a stable contract from the
/// start; each returns a user-facing error string, or `null` when valid.
class Validators {
  const Validators._();

  static String? requiredText(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  static String? notFutureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    if (value.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }
    return null;
  }

  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Start and end dates are required';
    }
    if (end.isBefore(start)) {
      return 'End date must be after start date';
    }
    return null;
  }
}
