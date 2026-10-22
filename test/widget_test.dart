import 'package:flutter_test/flutter_test.dart';
import 'package:melbet_manager_app/core/utils/app_utils.dart';
import 'package:melbet_manager_app/data/models/shift_report_model.dart';
import 'package:melbet_manager_app/data/models/user_model.dart';
import 'package:melbet_manager_app/data/mock/mock_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Melbet Shift Report Calculations', () {
    test('Calculates Commissions correctly at 3% deposit and 2% withdrawal', () {
      const deposit = 50000.0;
      const withdrawal = 30000.0;

      final depComm = AppUtils.depositCommission(deposit);
      final wdComm = AppUtils.withdrawalCommission(withdrawal);
      final totComm = AppUtils.totalCommission(depComm, wdComm);

      expect(depComm, equals(1500.0)); // 50,000 * 0.03
      expect(wdComm, equals(600.0));   // 30,000 * 0.02
      expect(totComm, equals(2100.0)); // 1,500 + 600
    });

    test('Calculates End Balance according to business formula', () {
      // Formula: (Initial Account + Total Deposit + Total Unprocessed + Added)
      //        - (Transfer to Next + Deposit Complaint + Withdrawal Complaint + Total Withdrawal + Taken)
      final endBalance = AppUtils.endBalance(
        initialAccount: 50000.0,
        totalDeposit: 25000.0,
        totalWithdrawal: 15000.0,
        totalUnprocessed: 2000.0,
        added: 500.0,
        transferToNext: 12000.0,
        depositComplaintAccepted: 1000.0,
        withdrawalComplaintAccepted: 500.0,
        taken: 200.0,
      );

      // (50,000 + 25,000 + 2,000 + 500) - (12,000 + 1,000 + 500 + 15,000 + 200)
      // = 77,500 - 28,700 = 48,800
      expect(endBalance, equals(48800.0));
    });

    test('Calculates Daily Expected Amount and Actual Amount (multi-shift)', () {
      // Expected: S1 InitReddy + S1 InitAccount + S2 EndBalance + S3 EndBalance
      //           + TotalCommission + TotalUnprocessed + Added - DepositComplaint - Taken
      final expected = AppUtils.expectedAmount(
        initialReddyS1: 10000.0,
        initialAccountS1: 40000.0,
        endBalanceS2: 30000.0,
        endBalanceS3: 25000.0,
        totalCommissionAll: 2500.0,
        totalUnprocessedAll: 1000.0,
        addedAll: 500.0,
        depositComplaintAll: 300.0,
        takenAll: 200.0,
      );
      // 10,000 + 40,000 + 30,000 + 25,000 + 2,500 + 1,000 + 500 - 300 - 200 = 108,500
      expect(expected, equals(108500.0));

      // Actual: EndReddy(S3) + EndBalance(S1+S2+S3) + TransferToNext(S3)
      final actual = AppUtils.actualAmount(
        endReddyS3: 12000.0,
        endBalanceS1: 20000.0,
        endBalanceS2: 30000.0,
        endBalanceS3: 25000.0,
        transferToNextS3: 3000.0,
      );
      // 12,000 + 20,000 + 30,000 + 25,000 + 3,000 = 90,000
      expect(actual, equals(90000.0));

      final deviation = AppUtils.shiftDeviation(
        actualAmount: actual,
        expectedAmount: expected,
      );
      expect(deviation, equals(-18500.0)); // 90,000 - 108,500
      expect(AppUtils.deviationTag(deviation), equals('negative'));
    });

    test('Calculates 24-hour Daily Deviation across 3 shifts', () {
      // 3 shifts in a 24-hour operating day
      final dailyDev = AppUtils.dailyDeviation(150.0, -50.0, -100.0);
      expect(dailyDev, equals(0.0));

      final dailyDevSurplus = AppUtils.dailyDeviation(200.0, 300.0, -100.0);
      expect(dailyDevSurplus, equals(400.0));

      final incompleteDay = AppUtils.dailyDeviation(200.0, null, -100.0);
      expect(incompleteDay, isNull);
    });
  });

  group('ShiftReport Data Model & Serialization', () {
    test('Serializes and deserializes ShiftReport JSON correctly', () {
      final now = DateTime(2026, 10, 12, 10, 0);
      final report = ShiftReport(
        id: 'test-report-1',
        employeeId: 'emp-1',
        employeeName: 'Abebe Kebede',
        operatingDate: DateTime(2026, 10, 12),
        shiftNumber: 1,
        initialReddy: 10000,
        initialAccount: 30000,
        totalDeposit: 15000,
        totalWithdrawal: 8000,
        endReddy: 11000,
        transferToNext: 5000,
        endBalance: 44000,
        depositCommission: 450,
        withdrawalCommission: 160,
        totalCommission: 610,
        expectedAmount: 40610,
        actualAmount: 60000,
        deviation: 19390,
        submittedAt: now,
        status: ReportStatus.submitted,
      );

      final json = report.toJson();
      final fromJson = ShiftReport.fromJson(json);

      expect(fromJson.id, equals(report.id));
      expect(fromJson.employeeName, equals('Abebe Kebede'));
      expect(fromJson.shiftNumber, equals(1));
      expect(fromJson.totalCommission, equals(610));
      expect(fromJson.status, equals(ReportStatus.submitted));
    });
  });

  group('MockRepository & Authentication', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Logs in valid user and rejects invalid credentials', () async {
      final repo = MockRepository();
      await repo.init();

      final admin = await repo.login('admin', 'admin123');
      expect(admin.success, isTrue);
      expect(admin.user?.role, equals(UserRole.admin));

      final emp = await repo.login('alem', 'emp123');
      expect(emp.success, isTrue);
      expect(emp.user?.role, equals(UserRole.employee));

      final invalid = await repo.login('alem', 'wrongpassword');
      expect(invalid.success, isFalse);
    });

    test('Loads pre-populated seed reports', () async {
      final repo = MockRepository();
      await repo.init();

      final reports = await repo.getAllReports();
      expect(reports.isNotEmpty, isTrue);

      final employees = await repo.getEmployees();
      expect(employees.length, greaterThanOrEqualTo(3));
    });
  });
}
