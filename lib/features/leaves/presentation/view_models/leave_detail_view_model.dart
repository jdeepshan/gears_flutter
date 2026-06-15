import 'package:flutter/foundation.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/leaves/data/leaves_api.dart';
import 'package:gears_flutter/features/leaves/data/models/leave.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_approval.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_attachment.dart';

/// Outcome of a leave action (delete, refer back, cancellation, etc.).
class LeaveDetailActionResult {
  const LeaveDetailActionResult({
    this.message,
    this.shouldPop = false,
  });

  final String? message;
  final bool shouldPop;
}

/// Result of downloading an attachment.
class AttachmentDownloadResult {
  const AttachmentDownloadResult._({
    this.filePath,
    this.isImage = false,
    this.message,
  });

  const AttachmentDownloadResult.success({
    required String filePath,
    required bool isImage,
  }) : this._(filePath: filePath, isImage: isImage);

  const AttachmentDownloadResult.failure(String message)
      : this._(message: message);

  final String? filePath;
  final bool isImage;
  final String? message;

  bool get isSuccess => filePath != null;
}

/// Mirrors iOS leave detail responsibilities from [LeaveApplicationViewModel].
class LeaveDetailViewModel extends ChangeNotifier {
  LeaveDetailViewModel({
    required this.leaveId,
    LeavesApi? api,
    this.onMessage,
  }) : _api = api ?? LeavesApi();

  final String leaveId;
  final LeavesApi _api;
  final void Function(String message)? onMessage;

  Leave? _leave;
  List<LeaveAttachment> _attachments = const [];
  List<LeaveApproval> _approvals = const [];
  bool _isLoading = false;
  bool _isLoadedData = false;

  Leave? get leave => _leave;
  List<LeaveAttachment> get attachments => List.unmodifiable(_attachments);
  List<LeaveApproval> get approvals => List.unmodifiable(_approvals);
  bool get isLoading => _isLoading;
  bool get isLoadedData => _isLoadedData;
  bool get showContent => _isLoadedData && _leave != null;

  Future<void> initialize() => loadDetails();

  Future<void> loadDetails() async {
    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      onMessage?.call('Subdomain is not configured.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final leave = await _api.getLeaveDetails(leaveId);
      var attachments = const <LeaveAttachment>[];
      var approvals = const <LeaveApproval>[];

      try {
        attachments = await _api.getAttachments(leaveId);
      } catch (_) {}

      try {
        approvals = await _api.getApprovalLevelList(leaveId);
      } catch (_) {}

      _leave = leave;
      _attachments = attachments;
      _approvals = approvals;
      _isLoadedData = true;
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

  Future<LeaveDetailActionResult> deleteLeave() =>
      _runAction(() => _api.deleteLeave(leaveId));

  Future<LeaveDetailActionResult> referBack() =>
      _runAction(() => _api.referBack(leaveId));

  Future<LeaveDetailActionResult> requestCancellation(String comment) =>
      _runAction(
        () => _api.requestCancellation(leaveId: leaveId, comment: comment),
      );

  Future<LeaveDetailActionResult> referbackCancellation() =>
      _runAction(() => _api.referbackCancellation(leaveId));

  Future<AttachmentDownloadResult> downloadAttachment(
    LeaveAttachment attachment,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final filePath = await _api.downloadAttachment(attachment);
      _isLoading = false;
      notifyListeners();
      return AttachmentDownloadResult.success(
        filePath: filePath,
        isImage: isImageFile(filePath),
      );
    } on LeavesApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      return AttachmentDownloadResult.failure(e.message);
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return AttachmentDownloadResult.failure('Could not open attachment.');
    }
  }

  static bool isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'}.contains(extension);
  }

  Future<LeaveDetailActionResult> _runAction(
    Future<String> Function() action, {
    bool popOnSuccess = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final message = await action();
      _isLoading = false;
      notifyListeners();
      return LeaveDetailActionResult(
        message: message.isNotEmpty ? message : null,
        shouldPop: popOnSuccess,
      );
    } on LeavesApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.statusCode != 401) {
        onMessage?.call(e.message);
      }
      return const LeaveDetailActionResult();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      onMessage?.call('Something went wrong. Please try again.');
      return const LeaveDetailActionResult();
    }
  }
}
