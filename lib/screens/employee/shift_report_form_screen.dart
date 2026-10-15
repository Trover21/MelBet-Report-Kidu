import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../data/models/shift_report_model.dart';

class ShiftReportFormScreen extends StatefulWidget {
  final String? reportId;
  const ShiftReportFormScreen({super.key, this.reportId});

  @override
  State<ShiftReportFormScreen> createState() => _ShiftReportFormScreenState();
}

class _ShiftReportFormScreenState extends State<ShiftReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  ShiftReport? _existingReport;

  // Selected values
  DateTime _operatingDate = DateTime.now();
  int _shiftNumber = 1;

  // Form controllers
  final _initialReddy = TextEditingController();
  final _initialAccount = TextEditingController();
  final _totalDeposit = TextEditingController();
  final _totalWithdrawal = TextEditingController();
  final _endReddy = TextEditingController();
  final _transferToNext = TextEditingController();
  final _depositComplaint = TextEditingController();
  final _withdrawalComplaint = TextEditingController();
  final _prevDayPending = TextEditingController();
  final _depositAfterShift = TextEditingController();
  final _withdrawalAfterShift = TextEditingController();
  final _depositBeforeShift = TextEditingController();
  final _withdrawalBeforeShift = TextEditingController();
  final _totalUnprocessed = TextEditingController();
  final _added = TextEditingController();
  final _taken = TextEditingController();

  bool _isSubmitting = false;
  bool _showCalculations = false;

  // Calculated values
  double _calcEndBalance = 0;
  double _calcDepComm = 0;
  double _calcWdComm = 0;
  double _calcTotComm = 0;
  double _calcExpected = 0;
  double _calcActual = 0;
  double _calcDeviation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.reportId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final existing = context
            .read<ReportProvider>()
            .reports
            .where((r) => r.id == widget.reportId)
            .firstOrNull;
        if (existing != null) {
          setState(() {
            _existingReport = existing;
            _operatingDate = existing.operatingDate;
            _shiftNumber = existing.shiftNumber;
            _initialReddy.text = existing.initialReddy > 0
                ? existing.initialReddy.toStringAsFixed(2)
                : '';
            _initialAccount.text = existing.initialAccount > 0
                ? existing.initialAccount.toStringAsFixed(2)
                : '';
            _totalDeposit.text = existing.totalDeposit > 0
                ? existing.totalDeposit.toStringAsFixed(2)
                : '';
            _totalWithdrawal.text = existing.totalWithdrawal > 0
                ? existing.totalWithdrawal.toStringAsFixed(2)
                : '';
            _endReddy.text = existing.endReddy > 0
                ? existing.endReddy.toStringAsFixed(2)
                : '';
            _transferToNext.text = existing.transferToNext > 0
                ? existing.transferToNext.toStringAsFixed(2)
                : '';
            _depositComplaint.text = existing.depositComplaintAccepted > 0
                ? existing.depositComplaintAccepted.toStringAsFixed(2)
                : '';
            _withdrawalComplaint.text =
                existing.withdrawalComplaintAccepted > 0
                    ? existing.withdrawalComplaintAccepted.toStringAsFixed(2)
                    : '';
            _prevDayPending.text =
                existing.prevDayPendingDepositApproved > 0
                    ? existing.prevDayPendingDepositApproved.toStringAsFixed(2)
                    : '';
            _depositAfterShift.text = existing.depositOkAfterShift > 0
                ? existing.depositOkAfterShift.toStringAsFixed(2)
                : '';
            _withdrawalAfterShift.text = existing.withdrawalOkAfterShift > 0
                ? existing.withdrawalOkAfterShift.toStringAsFixed(2)
                : '';
            _depositBeforeShift.text = existing.depositOkBeforeShift > 0
                ? existing.depositOkBeforeShift.toStringAsFixed(2)
                : '';
            _withdrawalBeforeShift.text =
                existing.withdrawalApprovedBeforeShift > 0
                    ? existing.withdrawalApprovedBeforeShift.toStringAsFixed(2)
                    : '';
            _totalUnprocessed.text = existing.totalUnprocessed > 0
                ? existing.totalUnprocessed.toStringAsFixed(2)
                : '';
            _added.text =
                existing.added > 0 ? existing.added.toStringAsFixed(2) : '';
            _taken.text =
                existing.taken > 0 ? existing.taken.toStringAsFixed(2) : '';
            _recalculate();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _initialReddy, _initialAccount, _totalDeposit, _totalWithdrawal,
      _endReddy, _transferToNext, _depositComplaint, _withdrawalComplaint,
      _prevDayPending, _depositAfterShift, _withdrawalAfterShift,
      _depositBeforeShift, _withdrawalBeforeShift, _totalUnprocessed,
      _added, _taken,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '')) ?? 0;

  void _recalculate() {
    final eb = AppUtils.endBalance(
      initialReddy: _val(_initialReddy),
      initialAccount: _val(_initialAccount),
      totalDeposit: _val(_totalDeposit),
      totalWithdrawal: _val(_totalWithdrawal),
      totalUnprocessed: _val(_totalUnprocessed),
      added: _val(_added),
      transferToNext: _val(_transferToNext),
      depositComplaintAccepted: _val(_depositComplaint),
      withdrawalComplaintAccepted: _val(_withdrawalComplaint),
      taken: _val(_taken),
    );
    final depComm = AppUtils.depositCommission(_val(_totalDeposit));
    final wdComm = AppUtils.withdrawalCommission(_val(_totalWithdrawal));
    final totComm = AppUtils.totalCommission(depComm, wdComm);
    final expected = AppUtils.expectedAmount(
      initialReddy: _val(_initialReddy),
      initialAccount: _val(_initialAccount),
      totalCommission: totComm,
    );
    final actual = AppUtils.actualAmount(
      endReddy: _val(_endReddy),
      endBalance: eb,
      transferToNext: _val(_transferToNext),
    );
    final dev = AppUtils.shiftDeviation(
        actualAmount: actual, expectedAmount: expected);

    setState(() {
      _calcEndBalance = eb;
      _calcDepComm = depComm;
      _calcWdComm = wdComm;
      _calcTotComm = totComm;
      _calcExpected = expected;
      _calcActual = actual;
      _calcDeviation = dev;
      _showCalculations = true;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _operatingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: AppTheme.darkTheme,
        child: child!,
      ),
    );
    if (picked != null) setState(() => _operatingDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    _recalculate();

    final auth = context.read<AuthProvider>();
    final reportProv = context.read<ReportProvider>();

    // ── Resubmit / Update existing report ────────────────────────
    if (widget.reportId != null && _existingReport != null) {
      final success = await reportProv.updateReport(_existingReport!.copyWith(
        operatingDate: _operatingDate,
        shiftNumber: _shiftNumber,
        initialReddy: _val(_initialReddy),
        initialAccount: _val(_initialAccount),
        totalDeposit: _val(_totalDeposit),
        totalWithdrawal: _val(_totalWithdrawal),
        endReddy: _val(_endReddy),
        transferToNext: _val(_transferToNext),
        depositComplaintAccepted: _val(_depositComplaint),
        withdrawalComplaintAccepted: _val(_withdrawalComplaint),
        prevDayPendingDepositApproved: _val(_prevDayPending),
        depositOkAfterShift: _val(_depositAfterShift),
        withdrawalOkAfterShift: _val(_withdrawalAfterShift),
        depositOkBeforeShift: _val(_depositBeforeShift),
        withdrawalApprovedBeforeShift: _val(_withdrawalBeforeShift),
        totalUnprocessed: _val(_totalUnprocessed),
        added: _val(_added),
        taken: _val(_taken),
        endBalance: _calcEndBalance,
        depositCommission: _calcDepComm,
        withdrawalCommission: _calcWdComm,
        totalCommission: _calcTotComm,
        expectedAmount: _calcExpected,
        actualAmount: _calcActual,
        deviation: _calcDeviation,
        lastModifiedAt: DateTime.now(),
        status: ReportStatus.submitted, // Resubmitted for admin review
      ));

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report updated and resubmitted successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reportProv.error ?? 'Failed to update report'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // ── Create new report ─────────────────────────────────────────
    final isDup = await reportProv.submitReport(ShiftReport(
      id: _uuid.v4(),
      employeeId: auth.user!.id,
      employeeName: auth.user!.name,
      operatingDate: _operatingDate,
      shiftNumber: _shiftNumber,
      initialReddy: _val(_initialReddy),
      initialAccount: _val(_initialAccount),
      totalDeposit: _val(_totalDeposit),
      totalWithdrawal: _val(_totalWithdrawal),
      endReddy: _val(_endReddy),
      transferToNext: _val(_transferToNext),
      depositComplaintAccepted: _val(_depositComplaint),
      withdrawalComplaintAccepted: _val(_withdrawalComplaint),
      prevDayPendingDepositApproved: _val(_prevDayPending),
      depositOkAfterShift: _val(_depositAfterShift),
      withdrawalOkAfterShift: _val(_withdrawalAfterShift),
      depositOkBeforeShift: _val(_depositBeforeShift),
      withdrawalApprovedBeforeShift: _val(_withdrawalBeforeShift),
      totalUnprocessed: _val(_totalUnprocessed),
      added: _val(_added),
      taken: _val(_taken),
      endBalance: _calcEndBalance,
      depositCommission: _calcDepComm,
      withdrawalCommission: _calcWdComm,
      totalCommission: _calcTotComm,
      expectedAmount: _calcExpected,
      actualAmount: _calcActual,
      deviation: _calcDeviation,
      submittedAt: DateTime.now(),
    ));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!isDup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProv.error ?? 'Failed to submit'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportId != null
            ? 'Edit & Resubmit Report'
            : 'Submit Shift Report'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          TextButton.icon(
            onPressed: _recalculate,
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('Preview'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_existingReport?.notes != null &&
                  _existingReport!.notes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppTheme.warning.withOpacity(0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.warning, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Correction Requested by Admin:',
                              style: TextStyle(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _existingReport!.notes!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Date & Shift Selectors ──────────────────────────
              _sectionHeader('Operating Information'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateSelector()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShiftSelector()),
                ],
              ),
              const SizedBox(height: 24),

              // ── Opening Balances ───────────────────────────────
              _sectionHeader('Opening Balances'),
              const SizedBox(height: 12),
              _buildField('Initial Reddy', _initialReddy,
                  hint: 'Opening Reddy amount'),
              const SizedBox(height: 12),
              _buildField('Initial Account', _initialAccount,
                  hint: 'Opening account amount'),
              const SizedBox(height: 24),

              // ── Transactions ───────────────────────────────────
              _sectionHeader('Transactions'),
              const SizedBox(height: 12),
              _buildField('Total Deposit', _totalDeposit,
                  hint: 'Total deposit for shift'),
              const SizedBox(height: 12),
              _buildField('Total Withdrawal', _totalWithdrawal,
                  hint: 'Total withdrawal for shift'),
              const SizedBox(height: 24),

              // ── Closing Balances ───────────────────────────────
              _sectionHeader('Closing Balances'),
              const SizedBox(height: 12),
              _buildField('End Reddy', _endReddy, hint: 'Closing Reddy amount'),
              const SizedBox(height: 12),
              _buildField('Transfer to Next', _transferToNext,
                  hint: 'Amount transferred to next shift'),
              const SizedBox(height: 24),

              // ── Complaints ─────────────────────────────────────
              _sectionHeader('Complaints (Optional)'),
              const SizedBox(height: 12),
              _buildField(
                  'Deposit Complaint Accepted', _depositComplaint,
                  hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField(
                  'Withdrawal Complaint Accepted', _withdrawalComplaint,
                  hint: '0.00', required: false),
              const SizedBox(height: 24),

              // ── Approvals ─────────────────────────────────────
              _sectionHeader('Approvals (Optional)'),
              const SizedBox(height: 12),
              _buildField(
                  'Prev-Day Pending Deposit Approved', _prevDayPending,
                  hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField(
                  'Deposit OK After Shift', _depositAfterShift,
                  hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField(
                  'Withdrawal OK After Shift', _withdrawalAfterShift,
                  hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField(
                  'Deposit OK Before Shift', _depositBeforeShift,
                  hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField(
                  'Withdrawal Approved Before Shift', _withdrawalBeforeShift,
                  hint: '0.00', required: false),
              const SizedBox(height: 24),

              // ── Adjustments ────────────────────────────────────
              _sectionHeader('Adjustments (Optional)'),
              const SizedBox(height: 12),
              _buildField('Total Unprocessed', _totalUnprocessed,
                  hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField('Added', _added, hint: '0.00', required: false),
              const SizedBox(height: 12),
              _buildField('Taken', _taken, hint: '0.00', required: false),
              const SizedBox(height: 24),

              // ── Preview Calculations ───────────────────────────
              if (_showCalculations) ...[
                _buildCalcCard(),
                const SizedBox(height: 24),
              ],

              // ── Submit Button ──────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: Icon(widget.reportId != null
                      ? Icons.check_circle_outline
                      : Icons.send_rounded),
                  label: Text(widget.reportId != null
                      ? 'Resubmit Report to Admin'
                      : 'Submit Report'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Operating Date',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 10)),
                Text(
                  AppUtils.formatDate(_operatingDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _shiftNumber,
          dropdownColor: AppTheme.bgCard,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
          isExpanded: true,
          items: List.generate(3, (i) {
            final num = i + 1;
            return DropdownMenuItem(
              value: num,
              child: Text(
                  '${AppConstants.shiftNames[i]}\n${AppConstants.shiftTimes[i]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
                      )),
            );
          }),
          onChanged: (v) => setState(() => _shiftNumber = v ?? 1),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String hint = '0.00', bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: 'ETB',
        suffixStyle: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.textMuted),
      ),
      onChanged: (_) {
        if (_showCalculations) _recalculate();
      },
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            }
          : null,
    );
  }

  Widget _buildCalcCard() {
    final devColor = _calcDeviation > 0
        ? AppTheme.deviationPositive
        : _calcDeviation < 0
            ? AppTheme.deviationNegative
            : AppTheme.deviationZero;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text('Calculated Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accent,
                      )),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _calcRow('End Balance', _calcEndBalance),
          _calcRow('Deposit Commission (3%)', _calcDepComm,
              color: AppTheme.success),
          _calcRow('Withdrawal Commission (2%)', _calcWdComm,
              color: AppTheme.success),
          _calcRow('Total Commission', _calcTotComm, color: AppTheme.success),
          const Divider(),
          _calcRow('Expected Amount', _calcExpected),
          _calcRow('Actual Amount', _calcActual),
          const Divider(),
          _calcRow('Deviation', _calcDeviation,
              color: devColor,
              isDeviation: true,
              isBold: true),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _calcRow(String label, double value,
      {Color? color, bool isDeviation = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            isDeviation
                ? AppUtils.formatDeviation(value)
                : AppUtils.formatCurrency(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
