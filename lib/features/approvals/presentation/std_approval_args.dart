class StdApprovalArgs {
  const StdApprovalArgs({
    required this.documentAutoId,
    required this.documentCode,
    required this.documentId,
    required this.approvalLevel,
  });

  final int documentAutoId;
  final String documentCode;
  final String documentId;
  final int approvalLevel;
}
