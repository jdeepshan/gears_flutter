import 'package:flutter/foundation.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/leaves/data/leaves_api.dart';
import 'package:gears_flutter/features/leaves/data/models/leave.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_filter_option.dart';
import 'package:gears_flutter/features/leaves/utils/leave_utils.dart';

/// Mirrors iOS [LeaveApplicationViewModel] list responsibilities.
class LeavesListViewModel extends ChangeNotifier {
  LeavesListViewModel({
    LeavesApi? api,
    this.onMessage,
  }) : _api = api ?? LeavesApi() {
    _fromDate = LeaveUtils.yearStart();
    _toDate = LeaveUtils.yearEnd();
  }

  final LeavesApi _api;
  final void Function(String message)? onMessage;

  final List<LeaveFilterOption> filters = LeaveFilterOption.defaults;

  late DateTime _fromDate;
  late DateTime _toDate;
  LeaveFilterOption _selectedFilter = LeaveFilterOption.initial;

  List<Leave> _leaves = [];
  bool _isLoading = false;
  bool _isLoadedData = false;
  bool _hasLoadedOnce = false;

  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  LeaveFilterOption get selectedFilter => _selectedFilter;
  List<Leave> get leaves => List.unmodifiable(_leaves);
  bool get isLoading => _isLoading;
  bool get isLoadedData => _isLoadedData;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get showEmptyState =>
      _isLoadedData && _hasLoadedOnce && !_isLoading && _leaves.isEmpty;
  bool get showList => _leaves.isNotEmpty;

  Future<void> initialize() => loadLeaves();

  Future<void> loadLeaves() async {
    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      onMessage?.call('Subdomain is not configured.');
      return;
    }

    _isLoading = true;
    _isLoadedData = true;
    _leaves = [];
    notifyListeners();

    try {
      final leaves = await _api.getLeaveList(
        from: _fromDate,
        to: _toDate,
        status: _selectedFilter.id,
      );
      _leaves = leaves;
      _hasLoadedOnce = true;
      _isLoading = false;
      notifyListeners();
    } on LeavesApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.statusCode != 401) {
        onMessage?.call(e.message);
      }
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      onMessage?.call('Something went wrong. Please try again.');
    }
  }

  void updateFromDate(DateTime date) {
    _fromDate = date;
    notifyListeners();
    loadLeaves();
  }

  void updateToDate(DateTime date) {
    _toDate = date;
    notifyListeners();
    loadLeaves();
  }

  Future<void> applyFilter(LeaveFilterOption filter) async {
    if (filter.id == _selectedFilter.id) return;
    _selectedFilter = filter;
    notifyListeners();
    await loadLeaves();
  }
}
