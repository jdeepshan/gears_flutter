import 'package:flutter/material.dart';

/// Bottom-nav tab 3 — mirrors [AppsFragment].
class AppsTabPage extends StatelessWidget {
  const AppsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Apps', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Linked applications',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.health_and_safety_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Gears QHSE'),
            subtitle: const Text('com.gears.gearsqhse'),
            trailing: FilledButton(
              onPressed: () {
                // TODO: launch external app / Play Store (AppsFragment)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open QHSE app — coming soon')),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ],
    );
  }
}
