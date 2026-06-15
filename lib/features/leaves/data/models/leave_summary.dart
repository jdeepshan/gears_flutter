class LeaveSummary {
  const LeaveSummary({
    this.balance,
    this.balanceDueToDate,
    this.balanceOnYearEnd,
    this.entitled,
    this.finaceYearExist,
    this.isDailyBasisAccrual,
    this.lastYearCFBalance,
    this.leaveTaken,
    this.noOfDays,
    this.openingBalance,
    this.policyMasterId,
  });

  final double? balance;
  final double? balanceDueToDate;
  final double? balanceOnYearEnd;
  final double? entitled;
  final double? finaceYearExist;
  final int? isDailyBasisAccrual;
  final double? lastYearCFBalance;
  final double? leaveTaken;
  final double? noOfDays;
  final double? openingBalance;
  final int? policyMasterId;
}
