import 'package:flutter/material.dart';

class LeaveDetailDateChip extends StatelessWidget {
  const LeaveDetailDateChip({
    required this.title,
    required this.date,
    super.key,
  });

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              date,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
