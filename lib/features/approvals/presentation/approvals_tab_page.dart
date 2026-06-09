import 'package:flutter/material.dart';

/// Bottom-nav tab 1 — mirrors [ApprovalsContainerFragment].
class ApprovalsTabPage extends StatefulWidget {
  const ApprovalsTabPage({super.key});

  @override
  State<ApprovalsTabPage> createState() => _ApprovalsTabPageState();
}

class _ApprovalsTabPageState extends State<ApprovalsTabPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'Others'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ApprovalListPlaceholder(
                title: 'Document approvals',
                subtitle: 'ApprovalsFragment — getAllDocumentApproval',
                icon: Icons.description_outlined,
              ),
              _ApprovalListPlaceholder(
                title: 'HRMS approvals',
                subtitle: 'HRMSApprovalsStdFragment — sme-profile-pending-approvals',
                icon: Icons.people_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApprovalListPlaceholder extends StatelessWidget {
  const _ApprovalListPlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title — coming soon')),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.pending_actions)),
              title: Text('Approval item ${i + 1}'),
              subtitle: const Text('Placeholder list item'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}
