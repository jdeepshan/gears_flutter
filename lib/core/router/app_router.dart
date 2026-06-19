import 'package:flutter/material.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/apps/presentation/apps_tab_page.dart';
import 'package:gears_flutter/features/approvals/presentation/approvals_tab_page.dart';
import 'package:gears_flutter/features/approvals/presentation/std_approval_args.dart';
import 'package:gears_flutter/features/approvals/presentation/std_expense_claim_approval_info_page.dart';
import 'package:gears_flutter/features/approvals/presentation/std_leave_approval_info_page.dart';
import 'package:gears_flutter/features/auth/presentation/login_page.dart';
import 'package:gears_flutter/features/auth/presentation/subdomain_page.dart';
import 'package:gears_flutter/features/profile/presentation/profile_tab_page.dart';
import 'package:gears_flutter/features/shell/presentation/home_shell_page.dart';
import 'package:gears_flutter/features/splash/presentation/splash_page.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.subdomain,
        builder: (context, state) => const SubdomainPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.leaveApprovalInfo,
        builder: (context, state) {
          final args = state.extra as StdApprovalArgs;
          return StdLeaveApprovalInfoPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.expenseClaimApprovalInfo,
        builder: (context, state) {
          final args = state.extra as StdApprovalArgs;
          return StdExpenseClaimApprovalInfoPage(args: args);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeApprovals,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ApprovalsTabPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeProfile,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileTabPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeApps,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AppsTabPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    if (location == AppRoutes.splash) {
      return null;
    }

    if (!SessionStorage.hasSubdomain &&
        location != AppRoutes.subdomain) {
      return AppRoutes.subdomain;
    }

    if (SessionStorage.hasSubdomain &&
        !SessionStorage.isLoggedIn &&
        location != AppRoutes.login &&
        location != AppRoutes.subdomain) {
      return AppRoutes.login;
    }

    if (SessionStorage.isLoggedIn &&
        (location == AppRoutes.login || location == AppRoutes.subdomain)) {
      return AppRoutes.homeProfile;
    }

    return null;
  }
}
