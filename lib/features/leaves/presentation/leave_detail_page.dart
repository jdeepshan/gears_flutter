import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gears_flutter/features/leaves/data/models/leave.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_approval.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_attachment.dart';
import 'package:gears_flutter/features/leaves/presentation/apply_leave_page.dart';
import 'package:gears_flutter/features/leaves/presentation/view_models/leave_detail_view_model.dart';
import 'package:gears_flutter/features/leaves/presentation/widgets/leave_detail_date_chip.dart';
import 'package:gears_flutter/features/leaves/utils/leave_utils.dart';

/// Mirrors iOS [LeaveDetailView].
class LeaveDetailPage extends StatefulWidget {
  const LeaveDetailPage({required this.leaveId, super.key});

  final String leaveId;

  @override
  State<LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {
  late final LeaveDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LeaveDetailViewModel(
      leaveId: widget.leaveId,
      onMessage: _showMessage,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _promptComment() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Comment',
            hintText: 'Enter cancellation comment',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _handleActionResult(LeaveDetailActionResult result) async {
    if (result.message != null) {
      _showMessage(result.message!);
    }
    if (result.shouldPop) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _onDelete() async {
    if (!await _confirm('Are you sure you want to delete this leave?')) return;
    await _handleActionResult(await _viewModel.deleteLeave());
  }

  Future<void> _onReferBack() async {
    if (!await _confirm('Are you sure you want to refer back this leave?')) {
      return;
    }
    await _handleActionResult(await _viewModel.referBack());
  }

  Future<void> _onRequestCancellation() async {
    if (!await _confirm(
      'Are you sure you want to request cancellation for this leave?',
    )) {
      return;
    }
    final comment = await _promptComment();
    if (comment == null || comment.isEmpty) return;
    await _handleActionResult(
      await _viewModel.requestCancellation(comment),
    );
  }

  Future<void> _onReferbackCancellation() async {
    if (!await _confirm(
      'Are you sure you want to refer back this cancellation?',
    )) {
      return;
    }
    await _handleActionResult(await _viewModel.referbackCancellation());
  }

  Future<void> _onDownloadAttachment(LeaveAttachment attachment) async {
    final result = await _viewModel.downloadAttachment(attachment);
    if (!mounted) return;

    if (!result.isSuccess) {
      if (result.message != null) _showMessage(result.message!);
      return;
    }

    final filePath = result.filePath!;
    if (result.isImage) {
      await _showImagePreview(filePath, attachment.name ?? 'Attachment');
      return;
    }

    final openResult = await OpenFilex.open(filePath);
    if (openResult.type != ResultType.done && mounted) {
      _showMessage(openResult.message);
    }
  }

  Future<void> _showImagePreview(String filePath, String title) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title, overflow: TextOverflow.ellipsis),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: InteractiveViewer(
                  child: Image.file(File(filePath), fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEdit() async {
    final shouldRefresh = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(
      MaterialPageRoute(
        builder: (_) => ApplyLeavePage(
          leaveId: widget.leaveId,
          initialLeave: _viewModel.leave,
          initialAttachments: _viewModel.attachments,
        ),
      ),
    );
    if (shouldRefresh == true) {
      await _viewModel.loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final leave = _viewModel.leave;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Leave Details'),
          ),
          body: Stack(
            children: [
              if (_viewModel.showContent && leave != null)
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LeaveInfoHeader(leave: leave),
                          const SizedBox(height: 12),
                          _LeavePeriodRow(leave: leave),
                          const SizedBox(height: 25),
                          _EmployeeDetailsSection(leave: leave),
                          if (_viewModel.attachments.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _AttachmentsSection(
                              attachments: _viewModel.attachments,
                              onDownload: _onDownloadAttachment,
                            ),
                          ],
                          const SizedBox(height: 25),
                          _MetaSection(leave: leave),
                          if (_viewModel.approvals.isNotEmpty) ...[
                            const SizedBox(height: 25),
                            _ApprovalsSection(
                              approvals: _viewModel.approvals,
                            ),
                          ],
                          const SizedBox(height: 25),
                          _ActionButtons(
                            leave: leave,
                            onEdit: _openEdit,
                            onDelete: _onDelete,
                            onReferBack: _onReferBack,
                            onRequestCancellation: _onRequestCancellation,
                            onReferbackCancellation: _onReferbackCancellation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_viewModel.isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaveInfoHeader extends StatelessWidget {
  const _LeaveInfoHeader({required this.leave});

  final Leave leave;

  @override
  Widget build(BuildContext context) {
    final status = LeaveUtils.itemStatus(leave);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            status.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          leave.leaveType?.name ?? '',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          leave.documentCode ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _LeavePeriodRow extends StatelessWidget {
  const _LeavePeriodRow({required this.leave});

  final Leave leave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LeaveDetailDateChip(
          title: 'Start Date',
          date: LeaveUtils.formatLongDisplayDate(leave.startDate),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'to',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        LeaveDetailDateChip(
          title: 'End Date',
          date: LeaveUtils.formatLongDisplayDate(leave.endDate),
        ),
      ],
    );
  }
}

class _EmployeeDetailsSection extends StatelessWidget {
  const _EmployeeDetailsSection({required this.leave});

  final Leave leave;

  @override
  Widget build(BuildContext context) {
    final coveringName = leave.coveringEmployee?.name ?? '';

    return Column(
      children: [
        if (leave.isHalfDay == 1)
          _DetailRow(
            title: 'Half day',
            value: leave.shiftType?.name ?? '',
          ),
        if (coveringName.isNotEmpty)
          _DetailRow(title: 'Covered employee', value: coveringName),
        _DetailRow(
          title: 'Require delegation',
          value: LeaveUtils.delegationRequiredText(leave),
        ),
        if ((leave.comment ?? '').isNotEmpty)
          _DetailRow(
            title: 'Comments',
            value: leave.comment!,
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.leave});

  final Leave leave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Created on: ${LeaveUtils.formatDisplayDate(leave.createdDate)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            LeaveUtils.confirmByText(leave),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.attachments,
    required this.onDownload,
  });

  final List<LeaveAttachment> attachments;
  final ValueChanged<LeaveAttachment> onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        for (final attachment in attachments)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(attachment.name ?? 'Attachment'),
              subtitle: (attachment.description ?? '').isEmpty
                  ? null
                  : Text(attachment.description!),
              trailing: IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () => onDownload(attachment),
              ),
            ),
          ),
      ],
    );
  }
}

class _ApprovalsSection extends StatelessWidget {
  const _ApprovalsSection({required this.approvals});

  final List<LeaveApproval> approvals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approval details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        for (final approval in approvals)
          _ApprovalCard(approval: approval),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.approval});

  final LeaveApproval approval;

  @override
  Widget build(BuildContext context) {
    final status = LeaveUtils.approvalStatus(approval);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    approval.approvedBy ?? '',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if ((approval.comment ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(approval.comment!),
                  ],
                  if ((approval.approvedDate ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      LeaveUtils.formatLongDisplayDate(approval.approvedDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.leave,
    required this.onEdit,
    required this.onDelete,
    required this.onReferBack,
    required this.onRequestCancellation,
    required this.onReferbackCancellation,
  });

  final Leave leave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReferBack;
  final VoidCallback onRequestCancellation;
  final VoidCallback onReferbackCancellation;

  @override
  Widget build(BuildContext context) {
    final confirmedYn = leave.confirmedYn ?? 0;
    final approvedYn = leave.approvedYn ?? 0;
    final requestedForCancel = leave.requestedForCancel ?? 0;
    final cancelled = leave.cancelled ?? 0;

    if (confirmedYn == 0 || confirmedYn == 2 || confirmedYn == 3) {
      return _DualActionBar(
        secondaryLabel: 'Edit',
        primaryLabel: 'Delete',
        onSecondary: onEdit,
        onPrimary: onDelete,
      );
    }

    if (confirmedYn == 1 && approvedYn == 0) {
      return _SingleActionBar(
        label: 'Refer Back',
        onPressed: onReferBack,
      );
    }

    if (approvedYn == 1 && requestedForCancel == 0) {
      return _SingleActionBar(
        label: 'Request Cancellation',
        color: const Color(0xFF2E7D32),
        onPressed: onRequestCancellation,
      );
    }

    if (requestedForCancel == 1 && cancelled == 0) {
      return _SingleActionBar(
        label: 'Refer Back Cancellation',
        onPressed: onReferbackCancellation,
      );
    }

    return const SizedBox.shrink();
  }
}

class _DualActionBar extends StatelessWidget {
  const _DualActionBar({
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondary,
            child: Text(secondaryLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onPrimary,
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}

class _SingleActionBar extends StatelessWidget {
  const _SingleActionBar({
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: color == null
            ? null
            : FilledButton.styleFrom(backgroundColor: color),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
