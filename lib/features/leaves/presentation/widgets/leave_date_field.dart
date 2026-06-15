import 'package:flutter/material.dart';
import 'package:gears_flutter/features/leaves/utils/leave_utils.dart';

class LeaveDateField extends StatelessWidget {
  const LeaveDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Material(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _pickDate(context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  LeaveUtils.formatDisplayDate(LeaveUtils.toApiDate(value)),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
