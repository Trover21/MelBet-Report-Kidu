import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/shift_report_model.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case ReportStatus.submitted:
        return AppTheme.info.withOpacity(0.2);
      case ReportStatus.reviewed:
        return AppTheme.warning.withOpacity(0.2);
      case ReportStatus.correctionRequested:
        return AppTheme.error.withOpacity(0.2);
      case ReportStatus.approved:
        return AppTheme.success.withOpacity(0.2);
    }
  }

  Color get _fg {
    switch (status) {
      case ReportStatus.submitted:
        return AppTheme.info;
      case ReportStatus.reviewed:
        return AppTheme.warning;
      case ReportStatus.correctionRequested:
        return AppTheme.error;
      case ReportStatus.approved:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _fg.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
