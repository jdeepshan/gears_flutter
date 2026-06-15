import 'package:flutter/material.dart';
import 'package:gears_flutter/features/leaves/data/models/leave.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_approval.dart';

abstract final class LeaveUtils {
  static const _apiDateFormat = 'yyyy-MM-dd';
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static DateTime yearStart([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  static DateTime yearEnd([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return DateTime(now.year, 12, 31);
  }

  static String toApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String formatDisplayDate(String? value) => _formatDate(value);

  static String formatLongDisplayDate(String? value) => _formatDate(value);

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return _formatDateTime(parsed);
    }

    if (value.length >= _apiDateFormat.length) {
      final parts = value.substring(0, 10).split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return _formatDateTime(DateTime(year, month, day));
        }
      }
    }

    return value;
  }

  static String _formatDateTime(DateTime date) {
    final month = _monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$day $month ${date.year}';
  }

  static String removeZerosFromEnd(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  static ({String count, String label}) daysCount(Leave leave) {
    if (leave.isHalfDay == 1) {
      return (count: leave.shift ?? '', label: 'Half day');
    }
    return (
      count: removeZerosFromEnd(leave.leaveType?.balance ?? 0),
      label: 'Days',
    );
  }

  static ({String label, Color color}) itemStatus(Leave leave) {
    final confirmedYn = leave.confirmedYn ?? -10;
    final approvedYn = leave.approvedYn ?? -10;
    final requestedForCancel = leave.requestedForCancel ?? 0;
    final cancelled = leave.cancelled ?? 0;

    if (confirmedYn == 0) {
      return (label: 'DRAFT', color: Colors.grey);
    }
    if (confirmedYn == 1 && approvedYn == 0) {
      return (label: 'CONFIRMED', color: Colors.blue);
    }
    if (confirmedYn == 2 || confirmedYn == 3) {
      return (label: 'REFERRED BACK', color: Colors.orange);
    }
    if (approvedYn == 1 && requestedForCancel == 0) {
      return (label: 'APPROVED', color: const Color(0xFF2E7D32));
    }
    if (requestedForCancel == 1 && cancelled == 0) {
      return (
        label: 'PENDING CANCELLATION',
        color: const Color(0xFFE2CE5B),
      );
    }
    if (requestedForCancel == 2 && cancelled == 0) {
      return (
        label: 'CANCELLATION REJECTED',
        color: const Color(0xFF9F2B68),
      );
    }
    if (cancelled == 1) {
      return (label: 'CANCELED', color: const Color(0xFF67C2EF));
    }
    return (label: '-', color: Colors.black);
  }

  static String confirmByText(Leave leave) {
    if (leave.confirmedYn == 0) {
      return 'Not confirmed yet';
    }
    final confirmedDate = leave.confirmedDate ?? '';
    if (confirmedDate.isEmpty) {
      return 'Unknown confirmation date';
    }
    return 'Confirmed by ${formatLongDisplayDate(confirmedDate)}';
  }

  static String delegationRequiredText(Leave leave) {
    return (leave.leaveInfo?.requireDelegation ?? 0) == 1 ? 'Yes' : 'No';
  }

  static ({String label, Color color}) approvalStatus(LeaveApproval approval) {
    if (approval.isRejected ?? false) {
      return (label: 'Referred Back', color: const Color(0xFFE53935));
    }
    if ((approval.approvalYn ?? 0) == 1) {
      return (label: 'Approved', color: const Color(0xFF2E7D32));
    }
    return (label: 'Pending', color: Colors.orange);
  }
}
