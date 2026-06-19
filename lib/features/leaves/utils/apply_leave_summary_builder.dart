import 'package:flutter/material.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_availability.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_summary.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_summary_item.dart';
import 'package:gears_flutter/features/leaves/utils/leave_utils.dart';

abstract final class ApplyLeaveSummaryBuilder {
  static List<LeaveSummaryItem> build({
    LeaveSummary? summary,
    LeaveAvailability? availability,
  }) {
    if (summary == null) return const [];

    final policyMasterId = summary.policyMasterId ?? 0;
    final isDaily = summary.isDailyBasisAccrual ?? 0;

    if (policyMasterId == 1 && isDaily == 0) {
      return [
        _item('Leave available', summary.balance, Colors.purple),
        _item('Leave applied', availability?.applied, Colors.green),
        _item('Working days', availability?.working, Colors.red),
        _item('Leave balance', availability?.balance, Colors.green),
      ];
    }

    if (policyMasterId == 1 && isDaily == 1) {
      return [
        _item('Annual eligibility', summary.noOfDays, Colors.blue),
        _item('Last year CF balance', summary.lastYearCFBalance, Colors.green),
        _item('Leave available', summary.balanceOnYearEnd, Colors.purple),
        _item('Leave applied', availability?.applied, Colors.green),
        _item('Working days', availability?.working, Colors.red),
        _item('Leave balance', availability?.balance, Colors.green),
      ];
    }

    if (policyMasterId == 3) {
      return [
        _item('Opening balance', summary.openingBalance, Colors.blue),
        _item('Balance due to date', summary.balanceDueToDate, Colors.green),
        _item('Total balances', summary.balanceDueToDate, Colors.purple),
        _item('Utilized', summary.leaveTaken, const Color(0xFF00897B)),
        _item('Total', summary.balance, Colors.orange),
        _item('Leave applied', availability?.applied, Colors.green),
        _item('Working days', availability?.working, Colors.red),
        _item('Leave balance', availability?.balance, Colors.green),
      ];
    }

    return const [];
  }

  static LeaveSummaryItem _item(String title, double? value, Color color) {
    return LeaveSummaryItem(
      title: title,
      count: value == null ? '-' : LeaveUtils.removeZerosFromEnd(value),
      color: color,
    );
  }
}
