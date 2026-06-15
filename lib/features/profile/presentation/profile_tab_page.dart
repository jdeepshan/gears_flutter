import 'package:flutter/material.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav tab 2 — mirrors [ProfileFragment].
class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  static const _shortcuts = [
    _ProfileShortcut(
      title: 'Pay slips',
      icon: Icons.payments_outlined,
      routeLabel: 'PaySlipsStdActivity',
    ),
    _ProfileShortcut(
      title: 'Leaves',
      icon: Icons.beach_access_outlined,
      routeLabel: 'LeavesStdActivity',
      route: AppRoutes.leaves,
    ),
    _ProfileShortcut(
      title: 'Expense claims',
      icon: Icons.receipt_long_outlined,
      routeLabel: 'ExpenseClaimStdActivity',
    ),
    _ProfileShortcut(
      title: 'Attendance',
      icon: Icons.schedule_outlined,
      routeLabel: 'AttendanceHistoryActivity',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employee name',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'employee@company.com',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
          children: [
            for (final shortcut in _shortcuts)
              _ShortcutCard(shortcut: shortcut),
          ],
        ),
        const SizedBox(height: 16),
        Text('Dashboard widgets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Request widgets'),
            subtitle: const Text('DashboardWidgetRequestAdapter — coming soon'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard widgets — coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileShortcut {
  const _ProfileShortcut({
    required this.title,
    required this.icon,
    required this.routeLabel,
    this.route,
  });

  final String title;
  final IconData icon;
  final String routeLabel;
  final String? route;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut});

  final _ProfileShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final route = shortcut.route;
          if (route != null) {
            context.push(route);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${shortcut.title} (${shortcut.routeLabel})')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                shortcut.icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                shortcut.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
