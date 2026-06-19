import 'package:gears_flutter/features/leaves/data/models/leave.dart';

class LeaveInitialData {
  const LeaveInitialData({
    required this.coveringEmployees,
    required this.leaveTypes,
    required this.coveringEmployeeRequired,
    required this.empId,
    this.employeeDisplayName,
  });

  final List<LeaveEmployee> coveringEmployees;
  final List<LeaveType> leaveTypes;
  final bool coveringEmployeeRequired;
  final int empId;
  final String? employeeDisplayName;
}
