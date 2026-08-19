import 'package:flutter/material.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:go_router/go_router.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _HomeTab(
      label: 'Approvals',
      icon: Icons.bookmark_added_outlined,
      selectedIcon: Icons.bookmark_added,
      route: AppRoutes.homeApprovals,
    ),
    _HomeTab(
      label: 'Profile',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: AppRoutes.homeProfile,
    ),
    _HomeTab(
      label: 'Apps',
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps,
      route: AppRoutes.homeApps,
    ),
  ];

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _onLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // TODO: Azure AD / Keycloak end session (HomeActivity.signOut).
    await SessionStorage.clearSession();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // TODO: dashboard drawer (NavDrawerAdapter)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Drawer menu — coming soon')),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => _onLogout(context),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
