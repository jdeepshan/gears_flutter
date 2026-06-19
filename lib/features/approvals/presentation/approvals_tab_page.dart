import 'package:flutter/material.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/approvals/data/approvals_api.dart';
import 'package:gears_flutter/features/approvals/data/models/hrms_approvals_std_response.dart';
import 'package:gears_flutter/features/approvals/presentation/approval_format_utils.dart';
import 'package:gears_flutter/features/approvals/presentation/std_approval_args.dart';
import 'package:go_router/go_router.dart';

const _approvalBackground = Color(0xFFF7F7F7);
const _approvalDarkGrey = Color(0xFF2A2C2F);
const _approvalGrey1 = Color(0xFF666666);

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
            children: const [
              _TransactionsApprovalsTab(),
              _HrmsApprovalsStdTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionsApprovalsTab extends StatelessWidget {
  const _TransactionsApprovalsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Document approvals'),
            subtitle: const Text('ApprovalsFragment — getAllDocumentApproval'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document approvals — coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Mirrors Android [HRMSApprovalsStdFragment] + [layout_approval_list_item].
class _HrmsApprovalsStdTab extends StatefulWidget {
  const _HrmsApprovalsStdTab();

  @override
  State<_HrmsApprovalsStdTab> createState() => _HrmsApprovalsStdTabState();
}

class _HrmsApprovalsStdTabState extends State<_HrmsApprovalsStdTab> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  final List<_ApprovalListEntry> _entries = [];

  List<_ApprovalListEntry> _buildEntries(List<HrmsApprovalDatum> approvals) {
    if (approvals.isEmpty) return [];

    final entries = <_ApprovalListEntry>[
      const _ApprovalListHeader(title: 'All Approvals'),
    ];

    for (final approval in approvals) {
      entries.add(
        _ApprovalListItem(
          datum: approval,
          documentId: approval.documentID ?? '',
          docCode: approval.docCode ?? '',
          companyName: approval.companyName ?? '',
          date: formatApprovalDate(approval.confirmedDate),
          narration: approval.narration ?? '',
          amount: approval.displayAmount,
        ),
      );
    }

    return entries;
  }

  Future<void> _fetchApprovals({required bool fromRefresh}) async {
    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _showMessage('Please enter the subdomain and try again.');
      return;
    }

    setState(() {
      if (fromRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final response = await ApprovalsApi(baseUrl).getHrmsApprovalsStd();
      final approvals = response.data ?? [];

      if (!mounted) return;

      setState(() {
        _entries
          ..clear()
          ..addAll(_buildEntries(approvals));
      });

      if (fromRefresh) {
        _showMessage('Approvals updated');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onApprovalItemTapped(HrmsApprovalDatum approval) async {
    final documentId = approval.documentID;
    if (documentId == null || documentId.isEmpty) return;

    final args = StdApprovalArgs(
      documentAutoId: approval.docAutoID ?? -1,
      documentCode: approval.docCode ?? '',
      documentId: documentId,
      approvalLevel: approval.approvalLevel ?? -1,
    );

    if (args.documentAutoId < 0 || args.approvalLevel < 0) {
      _showMessage('Invalid approval item');
      return;
    }

    final String route;
    switch (documentId) {
      case 'LA':
      case 'LAC':
        route = AppRoutes.leaveApprovalInfo;
      case 'EC':
        route = AppRoutes.expenseClaimApprovalInfo;
      default:
        return;
    }

    final approved = await context.push<bool>(route, extra: args);
    if (approved == true && mounted) {
      await _fetchApprovals(fromRefresh: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchApprovals(fromRefresh: false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasItems = _entries.any((entry) => entry is _ApprovalListItem);

    return ColoredBox(
      color: _approvalBackground,
      child: Stack(
        children: [
          RefreshIndicator(
            color: primary,
            onRefresh: () => _fetchApprovals(fromRefresh: true),
            child: hasItems
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      if (entry is _ApprovalListHeader) {
                        return _ApprovalListHeaderCard(title: entry.title);
                      }
                      return _ApprovalListItemCard(
                        item: entry as _ApprovalListItem,
                        onTap: () => _onApprovalItemTapped(entry.datum),
                      );
                    },
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 120)],
                  ),
          ),
          if (!hasItems && !_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 120,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const Text(
                    'No approvals available',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_isRefreshing)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApprovalListHeaderCard extends StatelessWidget {
  const _ApprovalListHeaderCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _approvalDarkGrey,
        ),
      ),
    );
  }
}

class _ApprovalListItemCard extends StatelessWidget {
  const _ApprovalListItemCard({
    required this.item,
    required this.onTap,
  });

  final _ApprovalListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DocLetterBadge(documentId: item.documentId),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.docCode,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.companyName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _approvalGrey1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _approvalGrey1,
                            ),
                          ),
                          if (item.amount != null && item.amount!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.amount!,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _approvalGrey1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (item.narration.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      item.narration,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _approvalGrey1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocLetterBadge extends StatelessWidget {
  const _DocLetterBadge({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _DocColorUtils.colorFor(documentId),
        shape: BoxShape.circle,
      ),
      child: Text(
        documentId.length > 4 ? documentId.substring(0, 4) : documentId,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

abstract class _ApprovalListEntry {
  const _ApprovalListEntry();
}

class _ApprovalListHeader extends _ApprovalListEntry {
  const _ApprovalListHeader({required this.title});

  final String title;
}

class _ApprovalListItem extends _ApprovalListEntry {
  const _ApprovalListItem({
    required this.datum,
    required this.documentId,
    required this.docCode,
    required this.companyName,
    required this.date,
    this.narration = '',
    this.amount,
  });

  final HrmsApprovalDatum datum;
  final String documentId;
  final String docCode;
  final String companyName;
  final String date;
  final String narration;
  final String? amount;
}

abstract final class _DocColorUtils {
  static Color colorFor(String docId) {
    switch (docId) {
      case 'PR':
      case 'DO':
      case 'RS':
      case 'GRV':
      case 'DN':
      case 'INV':
      case 'LA':
        return const Color(0xFF79C447);
      case 'WR':
      case 'WO':
      case 'LAC':
        return const Color(0xFFFFC107);
      case 'DR':
      case 'PO':
      case 'MR':
      case 'SI':
      case 'CN':
      case 'EC':
        return const Color(0xFFFF5454);
      case 'BRV':
        return const Color(0xFF67C2EF);
      case 'SR':
        return const Color(0xFFA4B7C1);
      case 'ST':
        return const Color(0xFF20C997);
      case 'BPV':
        return const Color(0xFFE83E8C);
      case 'JV':
        return const Color(0xFF6610F2);
      case 'PV':
        return const Color(0xFF20A8D8);
      case 'DI':
      case 'FA':
      case 'FAD':
      case 'PRN':
      case 'BS':
      case 'FADS':
      case 'BTN':
      case 'EX':
      case 'SA':
      case 'MI':
        return const Color(0xFF00008B);
      default:
        return Colors.black;
    }
  }
}

