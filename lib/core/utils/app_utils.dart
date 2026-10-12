import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppUtils {
  AppUtils._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final NumberFormat _intFormat = NumberFormat('#,##0');
  static final DateFormat _dateFormat = DateFormat(AppConstants.displayDateFormat);
  static final DateFormat _storageDateFormat = DateFormat(AppConstants.dateFormat);

  /// Format a double as currency (e.g. 12,345.67)
  static String formatCurrency(double value) => _currencyFormat.format(value);

  /// Format an integer with thousands separator
  static String formatInt(int value) => _intFormat.format(value);

  /// Format a DateTime for display (e.g. 12 Oct 2026)
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format a DateTime for storage (e.g. 2026-10-12)
  static String formatDateStorage(DateTime date) => _storageDateFormat.format(date);

  /// Parse a storage date string to DateTime
  static DateTime parseDate(String date) => _storageDateFormat.parse(date);

  /// Format DateTime with time
  static String formatDateTime(DateTime dt) =>
      DateFormat(AppConstants.dateTimeFormat).format(dt);

  /// Get deviation color tag: 'positive', 'negative', 'zero'
  static String deviationTag(double dev) {
    if (dev > 0) return 'positive';
    if (dev < 0) return 'negative';
    return 'zero';
  }

  /// Format deviation with explicit sign
  static String formatDeviation(double dev) {
    final formatted = _currencyFormat.format(dev.abs());
    if (dev > 0) return '+$formatted';
    if (dev < 0) return '-$formatted';
    return formatted;
  }

  /// Calculate deposit commission (3%)
  static double depositCommission(double totalDeposit) =>
      totalDeposit * AppConstants.depositCommissionRate;

  /// Calculate withdrawal commission (2%)
  static double withdrawalCommission(double totalWithdrawal) =>
      totalWithdrawal * AppConstants.withdrawalCommissionRate;

  /// Calculate total commission
  static double totalCommission(double depComm, double wdComm) =>
      depComm + wdComm;

  /// Calculate End Balance
  static double endBalance({
    required double initialReddy,
    required double initialAccount,
    required double totalDeposit,
    required double totalWithdrawal,
    required double totalUnprocessed,
    required double added,
    required double transferToNext,
    required double depositComplaintAccepted,
    required double withdrawalComplaintAccepted,
    required double taken,
  }) {
    final initialBalance = initialReddy + initialAccount;
    return (initialBalance + totalDeposit + totalUnprocessed + added) -
        (transferToNext + depositComplaintAccepted + withdrawalComplaintAccepted + taken);
  }

  /// Calculate Expected Amount
  static double expectedAmount({
    required double initialReddy,
    required double initialAccount,
    required double totalCommission,
  }) =>
      initialReddy + initialAccount + totalCommission;

  /// Calculate Actual Amount
  static double actualAmount({
    required double endReddy,
    required double endBalance,
    required double transferToNext,
  }) =>
      endReddy + endBalance + transferToNext;

  /// Calculate Shift Deviation
  static double shiftDeviation({
    required double actualAmount,
    required double expectedAmount,
  }) =>
      actualAmount - expectedAmount;

  /// Calculate 24-hour deviation from 3 shifts
  static double? dailyDeviation(double? s1, double? s2, double? s3) {
    if (s1 == null || s2 == null || s3 == null) return null;
    return s1 + s2 + s3;
  }
}
