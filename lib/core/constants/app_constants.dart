class AppConstants {
  AppConstants._();

  // Commission Rates
  static const double depositCommissionRate = 0.03;    // 3%
  static const double withdrawalCommissionRate = 0.02; // 2%

  // Shifts
  static const List<String> shiftNames = ['Shift 1', 'Shift 2', 'Shift 3'];
  static const List<String> shiftTimes = ['06:00 – 14:00', '14:00 – 22:00', '22:00 – 06:00'];

  // App Info
  static const String appName = 'Melbet Shift Manager';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyCurrentUser = 'current_user';
  static const String keyShiftReports = 'shift_reports';
  static const String keyUsers = 'users';

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
}
