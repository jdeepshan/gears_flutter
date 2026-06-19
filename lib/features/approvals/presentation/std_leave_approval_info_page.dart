import 'package:flutter/material.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/approvals/data/approvals_api.dart';
import 'package:gears_flutter/features/approvals/data/models/attachments_response.dart';
import 'package:gears_flutter/features/approvals/data/models/leave_std_details_response.dart';
import 'package:gears_flutter/features/approvals/presentation/approval_format_utils.dart';
import 'package:gears_flutter/features/approvals/presentation/std_approval_args.dart';
import 'package:gears_flutter/features/approvals/presentation/widgets/approval_detail_widgets.dart';
import 'package:go_router/go_router.dart';

class StdLeaveApprovalInfoPage extends StatefulWidget {
  const StdLeaveApprovalInfoPage({super.key, required this.args});

  final StdApprovalArgs args;

  @override
  State<StdLeaveApprovalInfoPage> createState() =>
      _StdLeaveApprovalInfoPageState();
}

class _StdLeaveApprovalInfoPageState extends State<StdLeaveApprovalInfoPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  LeaveStdDetailsData? _leaveData;
  List<AttachmentDatum> _attachments = const [];

  bool get _isCancellation =>
      widget.args.documentId.toUpperCase() == 'LAC';

  String get _title =>
      _isCancellation ? 'Leave Cancellation' : 'Leave Application';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _showMessage('Please enter the subdomain and try again.');
      if (mounted) context.pop();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApprovalsApi(baseUrl);
      final detailsResponse = await api.getLeaveStdDetails(
        widget.args.documentAutoId,
        isFromApproval: true,
      );

      if (detailsResponse.success != true || detailsResponse.data == null) {
        throw ApiException(detailsResponse.message ?? 'Failed to load details');
      }

      final attachmentsResponse = await api.getDocumentStdAttachments(
        widget.args.documentAutoId,
        'LA',
      );

      if (!mounted) return;

      setState(() {
        _leaveData = detailsResponse.data;
        _attachments = attachmentsResponse.data ?? [];
      });
    } on ApiException catch (e) {
      _showMessage(e.message);
      if (mounted) context.pop();
    } catch (e) {
      _showMessage(e.toString());
      if (mounted) context.pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitApproval({
    required int status,
    required bool commentOptional,
    required String dialogTitle,
    required String dialogMessage,
  }) async {
    final comment = await showApprovalCommentDialog(
      context: context,
      title: dialogTitle,
      message: dialogMessage,
      commentOptional: commentOptional,
    );
    if (comment == null || !mounted) return;

    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _showMessage('Please enter the subdomain and try again.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApprovalsApi(baseUrl).submitLeaveStdApproval(
        status: status,
        comment: comment,
        documentAutoId: widget.args.documentAutoId,
        approvalLevel: widget.args.approvalLevel,
        isCancellation: _isCancellation,
      );

      if (!mounted) return;

      if (response.success == true) {
        _showMessage(response.message ?? 'Success');
        context.pop(true);
      } else {
        _showMessage(response.message ?? 'Something went wrong');
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: approvalBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title),
            Text(
              widget.args.documentCode,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaveData == null
              ? const Center(child: Text('No details available'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EmployeeHeader(leaveData: _leaveData!),
                            _LeaveSummaryCard(leaveData: _leaveData!),
                            _LeaveDetailsCard(
                              leaveData: _leaveData!,
                              isCancellation: _isCancellation,
                            ),
                            if (_attachments.isNotEmpty)
                              ApprovalSectionCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        24,
                                        16,
                                        24,
                                        0,
                                      ),
                                      child: Text(
                                        'Attachments',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: approvalDarkGrey,
                                        ),
                                      ),
                                    ),
                                    ..._attachments.map(
                                      (attachment) => ApprovalAttachmentTile(
                                        attachment: attachment,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    ApprovalActionBar(
                      isSubmitting: _isSubmitting,
                      onApprove: () => _submitApproval(
                        status: 1,
                        commentOptional: true,
                        dialogTitle: 'Approve',
                        dialogMessage: _isCancellation
                            ? 'Are you sure you want to approve this leave cancellation?'
                            : 'Are you sure you want to approve this leave application?',
                      ),
                      onReferBack: () => _submitApproval(
                        status: 2,
                        commentOptional: false,
                        dialogTitle: 'Refer Back',
                        dialogMessage: _isCancellation
                            ? 'Are you sure you want to refer back this leave cancellation?'
                            : 'Are you sure you want to refer back this leave application?',
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({required this.leaveData});

  final LeaveStdDetailsData leaveData;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leaveData.formData?.eName2 ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: approvalDarkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            leaveData.formData?.empSecondaryCode ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: approvalGrey2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveSummaryCard extends StatelessWidget {
  const _LeaveSummaryCard({required this.leaveData});

  final LeaveStdDetailsData leaveData;

  @override
  Widget build(BuildContext context) {
    final leave = leaveData.leave;
    if (leave == null) return const SizedBox.shrink();

    return ApprovalSectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              leaveData.selectedLeaveType,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: approvalDarkGrey,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _buildStatTiles(leave),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatTiles(LeaveStdLeave leave) {
    if (leave.policyMasterID == 1 && leave.isDailyBasisAccrual == 0) {
      return [
        ApprovalStatTile(
          label: 'Available',
          value: formatApprovalNumber(leave.leaveAvailable),
        ),
        ApprovalStatTile(
          label: 'Applied',
          value: formatApprovalNumber(leave.days),
        ),
        ApprovalStatTile(
          label: 'Working Days',
          value: formatApprovalNumber(leave.workingDays),
        ),
        ApprovalStatTile(
          label: 'Balance',
          value: formatApprovalNumber(leave.balance),
        ),
      ];
    }

    if (leave.policyMasterID == 1 && leave.isDailyBasisAccrual == 1) {
      return [
        ApprovalStatTile(
          label: 'Eligibility',
          value: formatApprovalNumber(leave.annualEligibilityDays),
        ),
        ApprovalStatTile(
          label: 'CF Balance',
          value: formatApprovalNumber(leave.lastYearCFBalance),
        ),
        ApprovalStatTile(
          label: 'Applied',
          value: formatApprovalNumber(leave.days),
        ),
        ApprovalStatTile(
          label: 'Working Days',
          value: leave.isCalenderDays == 0
              ? formatApprovalNumber(leave.workingDays)
              : '-',
        ),
        ApprovalStatTile(
          label: 'Balance',
          value: formatApprovalNumber(leave.balance),
        ),
      ];
    }

    if (leave.policyMasterID == 3) {
      return [
        ApprovalStatTile(
          label: 'Opening Balance',
          value: formatApprovalNumber(leave.openingBalance),
        ),
        ApprovalStatTile(
          label: 'Balance Due to Date',
          value: formatApprovalNumber(leave.balanceToDate),
        ),
        ApprovalStatTile(
          label: 'Total',
          value: formatApprovalNumber(leave.leaveAvailable),
        ),
        ApprovalStatTile(
          label: 'Utilized',
          value: formatApprovalNumber(leave.utilized),
        ),
        ApprovalStatTile(
          label: 'Applied',
          value: formatApprovalNumber(leave.days),
        ),
        ApprovalStatTile(
          label: 'Working Days',
          value: leave.isCalenderDays == 0
              ? formatApprovalNumber(leave.workingDays)
              : '-',
        ),
        ApprovalStatTile(
          label: 'Balance',
          value: formatApprovalNumber(leave.balance),
        ),
      ];
    }

    return [
      ApprovalStatTile(
        label: 'Applied',
        value: formatApprovalNumber(leave.days),
      ),
      ApprovalStatTile(
        label: 'Balance',
        value: formatApprovalNumber(leave.balance),
      ),
    ];
  }
}

class _LeaveDetailsCard extends StatelessWidget {
  const _LeaveDetailsCard({
    required this.leaveData,
    required this.isCancellation,
  });

  final LeaveStdDetailsData leaveData;
  final bool isCancellation;

  @override
  Widget build(BuildContext context) {
    final leave = leaveData.leave;
    if (leave == null) return const SizedBox.shrink();

    final isHalfDay = leave.isHalfDay == 1;
    final startDateLabel = isHalfDay ? 'Date' : 'Start Date';
    final endDateLabel = isHalfDay ? 'Shift' : 'End Date';
    final endDateValue = isHalfDay
        ? (leave.shift == 0 ? 'Morning' : 'Evening')
        : formatApprovalDateTime(leave.endDate);

    final comment = isCancellation
        ? leave.cancelRequestComment
        : leave.comments;

    final coveringEmployee = _coveringEmployeeLabel(leave);

    return ApprovalSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: approvalDarkGrey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: startDateLabel,
                    value: formatApprovalDateTime(leave.startDate),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'to',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: approvalDarkGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: _DateBox(
                    label: endDateLabel,
                    value: endDateValue,
                  ),
                ),
              ],
            ),
          ),
          if (coveringEmployee != null)
            ApprovalField(
              label: 'Covered Employee',
              value: coveringEmployee,
            ),
          ApprovalField(
            label: 'Require Delegation',
            value: leave.requireDelegation == 1 ? 'Yes' : 'No',
          ),
          ApprovalField(
            label: 'Comments',
            value: displayComment(comment),
            valueColor: comment == null || comment.trim().isEmpty
                ? approvalGrey2
                : Colors.black,
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: approvalBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.entryDate == null
                      ? 'Created On : N/A'
                      : 'Created On : ${formatApprovalDate(leave.entryDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  leave.confirmedDate == null
                      ? 'Confirmed On : N/A'
                      : 'Confirmed by ${leave.confirmedByName ?? ''} on ${formatApprovalDateTime(leave.confirmedDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _coveringEmployeeLabel(LeaveStdLeave leave) {
    final coveringEmpId = leave.coveringEmpID;
    if (coveringEmpId == null || coveringEmpId == 0) return null;

    for (final drop in leaveData.formData?.coveringEmpDrop ?? const []) {
      if (drop.value == coveringEmpId) {
        return drop.label;
      }
    }
    return 'N/A';
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: approvalDarkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
