import 'package:flutter/material.dart';
import 'package:gears_flutter/features/approvals/data/models/attachments_response.dart';

const approvalBackground = Color(0xFFF7F7F7);
const approvalDarkGrey = Color(0xFF2A2C2F);
const approvalGrey1 = Color(0xFF666666);
const approvalGrey2 = Color(0xFF999999);
const approvalRed2 = Color(0xFFE74C3C);

class ApprovalSectionCard extends StatelessWidget {
  const ApprovalSectionCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 0),
  });

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class ApprovalStatTile extends StatelessWidget {
  const ApprovalStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: approvalGrey1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: approvalGrey1,
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalField extends StatelessWidget {
  const ApprovalField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: approvalDarkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? approvalGrey1,
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalAttachmentTile extends StatelessWidget {
  const ApprovalAttachmentTile({super.key, required this.attachment});

  final AttachmentDatum attachment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        Icons.attach_file,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        attachment.myFileName ?? 'Attachment',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: approvalDarkGrey,
        ),
      ),
      subtitle: attachment.attachmentDescription == null ||
              attachment.attachmentDescription!.isEmpty
          ? null
          : Text(
              attachment.attachmentDescription!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: approvalGrey2),
            ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attachment.myFileName ?? 'Attachment download — coming soon',
            ),
          ),
        );
      },
    );
  }
}

class ApprovalActionBar extends StatelessWidget {
  const ApprovalActionBar({
    super.key,
    required this.onApprove,
    required this.onReferBack,
    this.isSubmitting = false,
  });

  final VoidCallback onApprove;
  final VoidCallback onReferBack;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: isSubmitting ? null : onReferBack,
                  child: const Text(
                    'REFER BACK',
                    style: TextStyle(
                      color: approvalRed2,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: isSubmitting ? null : onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'APPROVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<String?> showApprovalCommentDialog({
  required BuildContext context,
  required String title,
  required String message,
  required bool commentOptional,
}) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: commentOptional
                    ? 'Add a comment (optional)'
                    : 'Add a comment',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final comment = controller.text.trim();
              if (!commentOptional && comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment is required')),
                );
                return;
              }
              Navigator.of(dialogContext).pop(comment);
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
