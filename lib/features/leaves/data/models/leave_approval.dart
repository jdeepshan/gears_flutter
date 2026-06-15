class LeaveApproval {
  const LeaveApproval({
    this.approvalYn,
    this.approvedBy,
    this.approvedDate,
    this.comment,
    this.isRejected,
  });

  final int? approvalYn;
  final String? approvedBy;
  final String? approvedDate;
  final String? comment;
  final bool? isRejected;
}
