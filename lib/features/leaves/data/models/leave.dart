class LeaveType {
  const LeaveType({
    this.id,
    this.name,
    this.balance,
    this.policyMasterId,
    this.leaveGroupId,
    this.isAllowsMinus,
    this.isCalendarDays,
    this.isAttachmentRequired,
    this.stretchDays,
    this.annualEligibilityDays,
    this.isDailyBasisAccrual,
    this.value,
  });

  final int? id;
  final String? name;
  final double? balance;
  final int? policyMasterId;
  final int? leaveGroupId;
  final int? isAllowsMinus;
  final bool? isCalendarDays;
  final bool? isAttachmentRequired;
  final int? stretchDays;
  final double? annualEligibilityDays;
  final int? isDailyBasisAccrual;
  final int? value;
}

class LeaveShift {
  const LeaveShift({this.id, this.name});

  final int? id;
  final String? name;
}

class LeaveEmployee {
  const LeaveEmployee({this.id, this.name});

  final int? id;
  final String? name;
}

class LeaveInfo {
  const LeaveInfo({this.requireDelegation});

  final double? requireDelegation;
}

class Leave {
  const Leave({
    this.id,
    this.documentCode,
    this.confirmedYn,
    this.approvedYn,
    this.cancelled,
    this.requestedForCancel,
    this.isHalfDay,
    this.shift,
    this.shiftType,
    this.startDate,
    this.endDate,
    this.leaveType,
    this.comment,
    this.createdDate,
    this.confirmedBy,
    this.confirmedDate,
    this.coveringEmployee,
    this.leaveInfo,
  });

  final int? id;
  final String? documentCode;
  final int? confirmedYn;
  final int? approvedYn;
  final int? cancelled;
  final int? requestedForCancel;
  final int? isHalfDay;
  final String? shift;
  final LeaveShift? shiftType;
  final String? startDate;
  final String? endDate;
  final LeaveType? leaveType;
  final String? comment;
  final String? createdDate;
  final String? confirmedBy;
  final String? confirmedDate;
  final LeaveEmployee? coveringEmployee;
  final LeaveInfo? leaveInfo;
}
