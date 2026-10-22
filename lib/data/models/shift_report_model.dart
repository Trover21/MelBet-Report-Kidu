enum ReportStatus { submitted, reviewed, correctionRequested, approved }

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.reviewed:
        return 'Reviewed';
      case ReportStatus.correctionRequested:
        return 'Correction Requested';
      case ReportStatus.approved:
        return 'Approved';
    }
  }

  String get value {
    switch (this) {
      case ReportStatus.submitted:
        return 'submitted';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.correctionRequested:
        return 'correction_requested';
      case ReportStatus.approved:
        return 'approved';
    }
  }

  static ReportStatus fromValue(String v) {
    switch (v) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'correction_requested':
        return ReportStatus.correctionRequested;
      case 'approved':
        return ReportStatus.approved;
      default:
        return ReportStatus.submitted;
    }
  }
}

class ShiftReport {
  final String id;
  final String employeeId;
  final String employeeName;
  final int teamNumber; // legacy compatibility
  final String teamName; // team the employee belongs to (e.g. "Team 1" or custom name)

  // Operating date & shift
  final DateTime operatingDate;
  final int shiftNumber; // 1, 2, or 3
  final String shiftStartTime; // e.g. "06:00" — entered by employee
  final String shiftEndTime;   // e.g. "14:00" — entered by employee

  // === Input Fields ===
  final double initialReddy;
  final double initialAccount;
  final double totalDeposit;
  final double totalWithdrawal;
  final double endReddy;
  final double transferToNext;
  final double depositComplaintAccepted;
  final double withdrawalComplaintAccepted;
  final double prevDayPendingDepositApproved;
  final double depositOkAfterShift;
  final double withdrawalOkAfterShift;
  final double depositOkBeforeShift;
  final double withdrawalApprovedBeforeShift;
  final double totalUnprocessed;
  final double added;
  final double taken;

  // === Calculated Fields ===
  final double endBalance;
  final double depositCommission;
  final double withdrawalCommission;
  final double totalCommission;
  final double expectedAmount;
  final double actualAmount;
  final double deviation;

  // === Meta ===
  final DateTime submittedAt;
  final DateTime? lastModifiedAt;
  final ReportStatus status;
  final String? notes;
  final List<CorrectionRecord> correctionHistory;

  const ShiftReport({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.teamNumber = 1,
    this.teamName = 'Team 1',
    required this.operatingDate,
    required this.shiftNumber,
    this.shiftStartTime = '',
    this.shiftEndTime = '',
    required this.initialReddy,
    required this.initialAccount,
    required this.totalDeposit,
    required this.totalWithdrawal,
    required this.endReddy,
    required this.transferToNext,
    this.depositComplaintAccepted = 0,
    this.withdrawalComplaintAccepted = 0,
    this.prevDayPendingDepositApproved = 0,
    this.depositOkAfterShift = 0,
    this.withdrawalOkAfterShift = 0,
    this.depositOkBeforeShift = 0,
    this.withdrawalApprovedBeforeShift = 0,
    this.totalUnprocessed = 0,
    this.added = 0,
    this.taken = 0,
    required this.endBalance,
    required this.depositCommission,
    required this.withdrawalCommission,
    required this.totalCommission,
    required this.expectedAmount,
    required this.actualAmount,
    required this.deviation,
    required this.submittedAt,
    this.lastModifiedAt,
    this.status = ReportStatus.submitted,
    this.notes,
    this.correctionHistory = const [],
  });

  String get shiftLabel {
    if (shiftStartTime.isNotEmpty && shiftEndTime.isNotEmpty) {
      return 'Shift $shiftNumber ($shiftStartTime – $shiftEndTime)';
    }
    return 'Shift $shiftNumber';
  }

  factory ShiftReport.fromJson(Map<String, dynamic> json) => ShiftReport(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        employeeName: json['employeeName'] as String,
        teamNumber: (json['teamNumber'] as num?)?.toInt() ?? 1,
        teamName: json['teamName'] as String? ??
            'Team ${(json['teamNumber'] as num?)?.toInt() ?? 1}',
        operatingDate: DateTime.parse(json['operatingDate'] as String),
        shiftNumber: json['shiftNumber'] as int,
        shiftStartTime: json['shiftStartTime'] as String? ?? '',
        shiftEndTime: json['shiftEndTime'] as String? ?? '',
        initialReddy: (json['initialReddy'] as num).toDouble(),
        initialAccount: (json['initialAccount'] as num).toDouble(),
        totalDeposit: (json['totalDeposit'] as num).toDouble(),
        totalWithdrawal: (json['totalWithdrawal'] as num).toDouble(),
        endReddy: (json['endReddy'] as num).toDouble(),
        transferToNext: (json['transferToNext'] as num).toDouble(),
        depositComplaintAccepted: (json['depositComplaintAccepted'] as num? ?? 0).toDouble(),
        withdrawalComplaintAccepted: (json['withdrawalComplaintAccepted'] as num? ?? 0).toDouble(),
        prevDayPendingDepositApproved: (json['prevDayPendingDepositApproved'] as num? ?? 0).toDouble(),
        depositOkAfterShift: (json['depositOkAfterShift'] as num? ?? 0).toDouble(),
        withdrawalOkAfterShift: (json['withdrawalOkAfterShift'] as num? ?? 0).toDouble(),
        depositOkBeforeShift: (json['depositOkBeforeShift'] as num? ?? 0).toDouble(),
        withdrawalApprovedBeforeShift: (json['withdrawalApprovedBeforeShift'] as num? ?? 0).toDouble(),
        totalUnprocessed: (json['totalUnprocessed'] as num? ?? 0).toDouble(),
        added: (json['added'] as num? ?? 0).toDouble(),
        taken: (json['taken'] as num? ?? 0).toDouble(),
        endBalance: (json['endBalance'] as num).toDouble(),
        depositCommission: (json['depositCommission'] as num).toDouble(),
        withdrawalCommission: (json['withdrawalCommission'] as num).toDouble(),
        totalCommission: (json['totalCommission'] as num).toDouble(),
        expectedAmount: (json['expectedAmount'] as num).toDouble(),
        actualAmount: (json['actualAmount'] as num).toDouble(),
        deviation: (json['deviation'] as num).toDouble(),
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        lastModifiedAt: json['lastModifiedAt'] != null
            ? DateTime.parse(json['lastModifiedAt'] as String)
            : null,
        status: ReportStatusExt.fromValue(json['status'] as String? ?? 'submitted'),
        notes: json['notes'] as String?,
        correctionHistory: (json['correctionHistory'] as List<dynamic>? ?? [])
            .map((e) => CorrectionRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'teamNumber': teamNumber,
        'teamName': teamName,
        'operatingDate': operatingDate.toIso8601String(),
        'shiftNumber': shiftNumber,
        'shiftStartTime': shiftStartTime,
        'shiftEndTime': shiftEndTime,
        'initialReddy': initialReddy,
        'initialAccount': initialAccount,
        'totalDeposit': totalDeposit,
        'totalWithdrawal': totalWithdrawal,
        'endReddy': endReddy,
        'transferToNext': transferToNext,
        'depositComplaintAccepted': depositComplaintAccepted,
        'withdrawalComplaintAccepted': withdrawalComplaintAccepted,
        'prevDayPendingDepositApproved': prevDayPendingDepositApproved,
        'depositOkAfterShift': depositOkAfterShift,
        'withdrawalOkAfterShift': withdrawalOkAfterShift,
        'depositOkBeforeShift': depositOkBeforeShift,
        'withdrawalApprovedBeforeShift': withdrawalApprovedBeforeShift,
        'totalUnprocessed': totalUnprocessed,
        'added': added,
        'taken': taken,
        'endBalance': endBalance,
        'depositCommission': depositCommission,
        'withdrawalCommission': withdrawalCommission,
        'totalCommission': totalCommission,
        'expectedAmount': expectedAmount,
        'actualAmount': actualAmount,
        'deviation': deviation,
        'submittedAt': submittedAt.toIso8601String(),
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'status': status.value,
        'notes': notes,
        'correctionHistory': correctionHistory.map((e) => e.toJson()).toList(),
      };

  ShiftReport copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    int? teamNumber,
    String? teamName,
    DateTime? operatingDate,
    int? shiftNumber,
    String? shiftStartTime,
    String? shiftEndTime,
    double? initialReddy,
    double? initialAccount,
    double? totalDeposit,
    double? totalWithdrawal,
    double? endReddy,
    double? transferToNext,
    double? depositComplaintAccepted,
    double? withdrawalComplaintAccepted,
    double? prevDayPendingDepositApproved,
    double? depositOkAfterShift,
    double? withdrawalOkAfterShift,
    double? depositOkBeforeShift,
    double? withdrawalApprovedBeforeShift,
    double? totalUnprocessed,
    double? added,
    double? taken,
    double? endBalance,
    double? depositCommission,
    double? withdrawalCommission,
    double? totalCommission,
    double? expectedAmount,
    double? actualAmount,
    double? deviation,
    DateTime? submittedAt,
    DateTime? lastModifiedAt,
    ReportStatus? status,
    String? notes,
    List<CorrectionRecord>? correctionHistory,
  }) =>
      ShiftReport(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        employeeName: employeeName ?? this.employeeName,
        teamNumber: teamNumber ?? this.teamNumber,
        teamName: teamName ?? this.teamName,
        operatingDate: operatingDate ?? this.operatingDate,
        shiftNumber: shiftNumber ?? this.shiftNumber,
        shiftStartTime: shiftStartTime ?? this.shiftStartTime,
        shiftEndTime: shiftEndTime ?? this.shiftEndTime,
        initialReddy: initialReddy ?? this.initialReddy,
        initialAccount: initialAccount ?? this.initialAccount,
        totalDeposit: totalDeposit ?? this.totalDeposit,
        totalWithdrawal: totalWithdrawal ?? this.totalWithdrawal,
        endReddy: endReddy ?? this.endReddy,
        transferToNext: transferToNext ?? this.transferToNext,
        depositComplaintAccepted: depositComplaintAccepted ?? this.depositComplaintAccepted,
        withdrawalComplaintAccepted: withdrawalComplaintAccepted ?? this.withdrawalComplaintAccepted,
        prevDayPendingDepositApproved: prevDayPendingDepositApproved ?? this.prevDayPendingDepositApproved,
        depositOkAfterShift: depositOkAfterShift ?? this.depositOkAfterShift,
        withdrawalOkAfterShift: withdrawalOkAfterShift ?? this.withdrawalOkAfterShift,
        depositOkBeforeShift: depositOkBeforeShift ?? this.depositOkBeforeShift,
        withdrawalApprovedBeforeShift: withdrawalApprovedBeforeShift ?? this.withdrawalApprovedBeforeShift,
        totalUnprocessed: totalUnprocessed ?? this.totalUnprocessed,
        added: added ?? this.added,
        taken: taken ?? this.taken,
        endBalance: endBalance ?? this.endBalance,
        depositCommission: depositCommission ?? this.depositCommission,
        withdrawalCommission: withdrawalCommission ?? this.withdrawalCommission,
        totalCommission: totalCommission ?? this.totalCommission,
        expectedAmount: expectedAmount ?? this.expectedAmount,
        actualAmount: actualAmount ?? this.actualAmount,
        deviation: deviation ?? this.deviation,
        submittedAt: submittedAt ?? this.submittedAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        correctionHistory: correctionHistory ?? this.correctionHistory,
      );
}

class CorrectionRecord {
  final String correctedBy;
  final DateTime correctedAt;
  final String reason;

  const CorrectionRecord({
    required this.correctedBy,
    required this.correctedAt,
    required this.reason,
  });

  factory CorrectionRecord.fromJson(Map<String, dynamic> json) =>
      CorrectionRecord(
        correctedBy: json['correctedBy'] as String,
        correctedAt: DateTime.parse(json['correctedAt'] as String),
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
        'correctedBy': correctedBy,
        'correctedAt': correctedAt.toIso8601String(),
        'reason': reason,
      };
}
