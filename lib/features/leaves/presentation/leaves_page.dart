import 'package:flutter/material.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_filter_option.dart';
import 'package:gears_flutter/features/leaves/presentation/apply_leave_page.dart';
import 'package:gears_flutter/features/leaves/presentation/leave_detail_page.dart';
import 'package:gears_flutter/features/leaves/presentation/view_models/leaves_list_view_model.dart';
import 'package:gears_flutter/features/leaves/presentation/widgets/leave_date_field.dart';
import 'package:gears_flutter/features/leaves/presentation/widgets/leave_list_item.dart';

/// Mirrors iOS [LeavesListView].
class LeavesPage extends StatefulWidget {
  const LeavesPage({super.key});

  @override
  State<LeavesPage> createState() => _LeavesPageState();
}

class _LeavesPageState extends State<LeavesPage> {
  late final LeavesListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LeavesListViewModel(
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

  Future<void> _pickFilter() async {
    final selected = await showModalBottomSheet<LeaveFilterOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Filter by status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final filter in _viewModel.filters)
                ListTile(
                  title: Text(filter.name),
                  trailing: filter.id == _viewModel.selectedFilter.id
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, filter),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _viewModel.applyFilter(selected);
    }
  }

  Future<void> _openApplyLeave() async {
    final shouldRefresh =
        await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ApplyLeavePage(),
      ),
    );
    if (shouldRefresh == true) {
      await _viewModel.loadLeaves();
    }
  }

  Future<void> _openLeaveDetail(int id) async {
    final shouldRefresh =
        await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeaveDetailPage(leaveId: '$id'),
      ),
    );
    if (shouldRefresh == true) {
      await _viewModel.loadLeaves();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Leaves'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openApplyLeave,
            child: const Icon(Icons.add),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _LeavesFilterBar(
                    fromDate: _viewModel.fromDate,
                    toDate: _viewModel.toDate,
                    selectedFilter: _viewModel.selectedFilter,
                    onFromDateChanged: _viewModel.updateFromDate,
                    onToDateChanged: _viewModel.updateToDate,
                    onFilterTap: _pickFilter,
                  ),
                  Expanded(
                    child: _LeavesBody(
                      viewModel: _viewModel,
                      colorScheme: colorScheme,
                      onLeaveTap: _openLeaveDetail,
                    ),
                  ),
                ],
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

class _LeavesBody extends StatelessWidget {
  const _LeavesBody({
    required this.viewModel,
    required this.colorScheme,
    required this.onLeaveTap,
  });

  final LeavesListViewModel viewModel;
  final ColorScheme colorScheme;
  final ValueChanged<int> onLeaveTap;

  @override
  Widget build(BuildContext context) {
    if (viewModel.showList) {
      return RefreshIndicator(
        onRefresh: viewModel.loadLeaves,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 24, bottom: 88),
          itemCount: viewModel.leaves.length,
          itemBuilder: (context, index) {
            final leave = viewModel.leaves[index];
            return LeaveListItem(
              leave: leave,
              onTap: () {
                final id = leave.id;
                if (id != null) onLeaveTap(id);
              },
            );
          },
        ),
      );
    }

    if (viewModel.showEmptyState) {
      return RefreshIndicator(
        onRefresh: viewModel.loadLeaves,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No data found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _LeavesFilterBar extends StatelessWidget {
  const _LeavesFilterBar({
    required this.fromDate,
    required this.toDate,
    required this.selectedFilter,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onFilterTap,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final LeaveFilterOption selectedFilter;
  final ValueChanged<DateTime> onFromDateChanged;
  final ValueChanged<DateTime> onToDateChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LeaveDateField(
                label: 'From',
                value: fromDate,
                onChanged: onFromDateChanged,
              ),
              const SizedBox(width: 16),
              LeaveDateField(
                label: 'To',
                value: toDate,
                onChanged: onToDateChanged,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Filter',
                onPressed: onFilterTap,
                icon: Icon(
                  Icons.tune,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          if (selectedFilter.id != LeaveFilterOption.all.id &&
              selectedFilter.id != LeaveFilterOption.initial.id) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Text(
                selectedFilter.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
