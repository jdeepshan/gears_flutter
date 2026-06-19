abstract final class AppRoutes {
  static const splash = '/';
  static const subdomain = '/subdomain';
  static const login = '/login';
  static const home = '/home';
  static const homeApprovals = '/home/approvals';
  static const homeProfile = '/home/profile';
  static const homeApps = '/home/apps';
  static const leaveApprovalInfo = '/approvals/leave';
  static const expenseClaimApprovalInfo = '/approvals/expense-claim';
  static const leaves = '/leaves';

  static String leaveDetail(String leaveId) => '$leaves/$leaveId';
}
