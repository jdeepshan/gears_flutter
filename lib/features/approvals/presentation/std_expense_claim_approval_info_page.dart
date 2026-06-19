import 'package:flutter/material.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/approvals/data/approvals_api.dart';
import 'package:gears_flutter/features/approvals/data/models/attachments_response.dart';
import 'package:gears_flutter/features/approvals/data/models/claim_std_details_response.dart';
import 'package:gears_flutter/features/approvals/presentation/approval_format_utils.dart';
import 'package:gears_flutter/features/approvals/presentation/std_approval_args.dart';
import 'package:gears_flutter/features/approvals/presentation/widgets/approval_detail_widgets.dart';
import 'package:go_router/go_router.dart';

class StdExpenseClaimApprovalInfoPage extends StatefulWidget {
  const StdExpenseClaimApprovalInfoPage({super.key, required this.args});

  final StdApprovalArgs args;

  @override
  State<StdExpenseClaimApprovalInfoPage> createState() =>
      _StdExpenseClaimApprovalInfoPageState();
}

class _StdExpenseClaimApprovalInfoPageState
    extends State<StdExpenseClaimApprovalInfoPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  ClaimStdDetailsData? _claimData;
  List<AttachmentDatum> _attachments = const [];

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
      final detailsResponse = await api.getExpenseClaimStdDetails(
        widget.args.documentAutoId,
      );

      if (detailsResponse.success != true || detailsResponse.data == null) {
        throw ApiException(detailsResponse.message ?? 'Failed to load details');
      }

      final attachmentsResponse = await api.getDocumentStdAttachments(
        widget.args.documentAutoId,
        'EC',
      );

      if (!mounted) return;

      setState(() {
        _claimData = detailsResponse.data;
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
      final response = await ApprovalsApi(baseUrl).submitClaimStdApproval(
        documentAutoId: widget.args.documentAutoId,
        status: status,
        comment: comment,
        approvalLevel: widget.args.approvalLevel,
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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: approvalBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expense Claim'),
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
          : _claimData == null
              ? const Center(child: Text('No details available'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EmployeeHeader(claimData: _claimData!),
                            ApprovalSectionCard(
                              child: Column(
                                children: [
                                  ...?_claimData!.details?.map(
                                    (detail) => _ClaimDetailItem(
                                      detail: detail,
                                      showDivider: detail !=
                                          _claimData!.details!.last,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Total :',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_claimData!.masterData?.claimBy?.payCurrency ?? ''} ${_claimData!.detTot ?? ''}'
                                              .trim(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ApprovalSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ApprovalField(
                                    label: 'Comment',
                                    value: displayComment(
                                      _claimData!
                                          .masterData?.comments,
                                    ),
                                    valueColor: _claimData!
                                                .masterData?.comments ==
                                            null
                                        ? approvalGrey2
                                        : Colors.black,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      16,
                                    ),
                                    child: Text(
                                      'Confirmed on ${formatApprovalDateTime(_claimData!.masterData?.confirmedDate)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: approvalGrey2,
                                      ),
                                    ),
                                  ),
                                  if (_attachments.isNotEmpty) ...[
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        0,
                                      ),
                                      child: Text(
                                        'Attachments',
                                        textAlign: TextAlign.center,
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
                        dialogMessage:
                            'Are you sure you want to approve this claim?',
                      ),
                      onReferBack: () => _submitApproval(
                        status: 2,
                        commentOptional: false,
                        dialogTitle: 'Refer Back',
                        dialogMessage:
                            'Are you sure you want to refer back this claim?',
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({required this.claimData});

  final ClaimStdDetailsData claimData;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            claimData.masterData?.claimedByEmpName ?? '',
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
            claimData.masterData?.claimedByEmpCode ?? '',
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

class _ClaimDetailItem extends StatelessWidget {
  const _ClaimDetailItem({
    required this.detail,
    required this.showDivider,
  });

  final ClaimStdDetail detail;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.description ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: approvalDarkGrey,
                      ),
                    ),
                    if (detail.exCat != null && detail.exCat!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail.exCat!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: approvalGrey2,
                        ),
                      ),
                    ],
                    if (detail.segStr != null && detail.segStr!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail.segStr!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: approvalGrey2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${detail.empCurrency ?? ''} ${detail.lcAmount ?? ''}'
                          .trim(),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: approvalDarkGrey,
                      ),
                    ),
                    if (detail.transactionCurrency != null &&
                        detail.trAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${detail.transactionCurrency} ${detail.trAmount}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: approvalGrey2,
                        ),
                      ),
                    ],
                    if (detail.exRate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ex Rate: ${detail.exRate}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: approvalGrey2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Ref : ${detail.referenceNo ?? ''}',
              style: const TextStyle(fontSize: 12, color: approvalGrey2),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Divider(height: 1, color: Colors.grey.shade400),
          ),
      ],
    );
  }
}
