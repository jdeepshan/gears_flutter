class LeaveAvailability {
  const LeaveAvailability({
    this.working,
    this.applied,
    this.balance,
    this.deductionApplicable,
  });

  final double? working;
  final double? applied;
  final double? balance;
  final double? deductionApplicable;
}
