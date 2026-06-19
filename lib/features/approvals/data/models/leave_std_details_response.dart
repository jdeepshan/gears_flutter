class LeaveStdDetailsResponse {
  const LeaveStdDetailsResponse({
    this.data,
    this.message,
    this.success,
  });

  final LeaveStdDetailsData? data;
  final String? message;
  final bool? success;

  factory LeaveStdDetailsResponse.fromJson(Map<String, dynamic> json) {
    return LeaveStdDetailsResponse(
      data: json['data'] == null
          ? null
          : LeaveStdDetailsData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }
}

class LeaveStdDetailsData {
  const LeaveStdDetailsData({
    this.formData,
    this.leave,
  });

  final LeaveStdFormData? formData;
  final LeaveStdLeave? leave;

  factory LeaveStdDetailsData.fromJson(Map<String, dynamic> json) {
    return LeaveStdDetailsData(
      formData: json['formData'] == null
          ? null
          : LeaveStdFormData.fromJson(json['formData'] as Map<String, dynamic>),
      leave: json['leave'] == null
          ? null
          : LeaveStdLeave.fromJson(json['leave'] as Map<String, dynamic>),
    );
  }

  String get selectedLeaveType {
    final leaveTypeId = leave?.leaveType;
    if (leaveTypeId == null) return '';

    for (final drop in formData?.leaveTypeDrop ?? const []) {
      if (drop.leaveTypeID == leaveTypeId) {
        return drop.label ?? '';
      }
    }
    return '';
  }
}

class LeaveStdFormData {
  const LeaveStdFormData({
    this.coveringEmpDrop,
    this.empSecondaryCode,
    this.eName2,
    this.leaveTypeDrop,
  });

  final List<CoveringEmpDrop>? coveringEmpDrop;
  final String? empSecondaryCode;
  final String? eName2;
  final List<LeaveTypeDrop>? leaveTypeDrop;

  factory LeaveStdFormData.fromJson(Map<String, dynamic> json) {
    return LeaveStdFormData(
      coveringEmpDrop: (json['covering_emp_drop'] as List<dynamic>?)
          ?.map((e) => CoveringEmpDrop.fromJson(e as Map<String, dynamic>))
          .toList(),
      empSecondaryCode: json['EmpSecondaryCode'] as String?,
      eName2: json['Ename2'] as String?,
      leaveTypeDrop: (json['leave_type_drop'] as List<dynamic>?)
          ?.map((e) => LeaveTypeDrop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CoveringEmpDrop {
  const CoveringEmpDrop({this.label, this.value});

  final String? label;
  final int? value;

  factory CoveringEmpDrop.fromJson(Map<String, dynamic> json) {
    return CoveringEmpDrop(
      label: json['label'] as String?,
      value: json['value'] as int?,
    );
  }
}

class LeaveTypeDrop {
  const LeaveTypeDrop({this.label, this.leaveTypeID});

  final String? label;
  final int? leaveTypeID;

  factory LeaveTypeDrop.fromJson(Map<String, dynamic> json) {
    return LeaveTypeDrop(
      label: json['label'] as String?,
      leaveTypeID: json['leaveTypeID'] as int?,
    );
  }
}

class LeaveStdLeave {
  const LeaveStdLeave({
    this.annualEligibilityDays,
    this.balance,
    this.balanceToDate,
    this.cancelRequestComment,
    this.comments,
    this.confirmedByName,
    this.confirmedDate,
    this.coveringEmpID,
    this.days,
    this.endDate,
    this.entryDate,
    this.isCalenderDays,
    this.isDailyBasisAccrual,
    this.isHalfDay,
    this.lastYearCFBalance,
    this.leaveAvailable,
    this.leaveType,
    this.openingBalance,
    this.policyMasterID,
    this.requireDelegation,
    this.shift,
    this.startDate,
    this.utilized,
    this.workingDays,
  });

  final double? annualEligibilityDays;
  final double? balance;
  final double? balanceToDate;
  final String? cancelRequestComment;
  final String? comments;
  final String? confirmedByName;
  final String? confirmedDate;
  final int? coveringEmpID;
  final double? days;
  final String? endDate;
  final String? entryDate;
  final int? isCalenderDays;
  final int? isDailyBasisAccrual;
  final int? isHalfDay;
  final double? lastYearCFBalance;
  final double? leaveAvailable;
  final int? leaveType;
  final double? openingBalance;
  final int? policyMasterID;
  final int? requireDelegation;
  final int? shift;
  final String? startDate;
  final double? utilized;
  final double? workingDays;

  factory LeaveStdLeave.fromJson(Map<String, dynamic> json) {
    return LeaveStdLeave(
      annualEligibilityDays: _toDouble(json['annualEligibilityDays']),
      balance: _toDouble(json['balance']),
      balanceToDate: _toDouble(json['balanceToDate']),
      cancelRequestComment: json['cancelRequestComment'] as String?,
      comments: json['comments'] as String?,
      confirmedByName: json['confirmedByName'] as String?,
      confirmedDate: json['confirmedDate'] as String?,
      coveringEmpID: json['coveringEmpID'] as int?,
      days: _toDouble(json['days']),
      endDate: json['endDate'] as String?,
      entryDate: json['entryDate'] as String?,
      isCalenderDays: json['isCalenderDays'] as int?,
      isDailyBasisAccrual: json['isDailyBasisAccrual'] as int?,
      isHalfDay: json['isHalfDay'] as int?,
      lastYearCFBalance: _toDouble(json['lastYearCFBalance']),
      leaveAvailable: _toDouble(json['leaveAvailable']),
      openingBalance: _toDouble(json['openingBalance']),
      policyMasterID: json['policyMasterID'] as int?,
      requireDelegation: json['require_delegation'] as int?,
      shift: json['shift'] as int?,
      startDate: json['startDate'] as String?,
      utilized: _toDouble(json['utilized']),
      workingDays: _toDouble(json['workingDays']),
      leaveType: json['leaveType'] as int?,
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
