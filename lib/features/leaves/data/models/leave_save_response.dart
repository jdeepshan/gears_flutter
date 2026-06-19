class LeaveSaveResponse {
  const LeaveSaveResponse({
    required this.success,
    required this.message,
    this.leaveCoveringEmpStatus = 0,
  });

  final bool success;
  final String message;
  final int leaveCoveringEmpStatus;
}
