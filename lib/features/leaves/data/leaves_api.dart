import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gears_flutter/core/network/api_client.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/leaves/data/models/leave.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_approval.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_attachment.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_availability.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_initial_data.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_save_response.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_summary.dart';
import 'package:gears_flutter/features/leaves/utils/leave_utils.dart';
import 'package:path_provider/path_provider.dart';

class LeavesApi {
  LeavesApi({String? baseUrl})
      : _baseUrl = baseUrl ?? SessionStorage.subdomainUrl ?? '',
        _dio = ApiClient.create(baseUrl ?? SessionStorage.subdomainUrl ?? '');

  final String _baseUrl;
  final Dio _dio;

  Future<List<Leave>> getLeaveList({
    required DateTime from,
    required DateTime to,
    required String status,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sme-leaves-dataTable',
        data: {
          'from': LeaveUtils.toApiDate(from),
          'to': LeaveUtils.toApiDate(to),
          'status': status,
          'isFrom': 1,
        },
      );
      return _mapLeaveList(response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Leave> getLeaveDetails(String leaveId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-leave/$leaveId',
      );
      return _mapLeaveDetails(int.tryParse(leaveId) ?? 0, response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<LeaveAttachment>> getAttachments(String leaveId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-attachment/$leaveId/LA',
      );
      return _mapAttachments(response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<LeaveApproval>> getApprovalLevelList(String leaveId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/getSmeApprovalData',
        data: {
          'documentID': 'LA',
          'documentSystemCode': leaveId,
        },
      );
      return _mapApprovalList(response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<String> deleteLeave(String leaveId) async {
    return _mapActionResponse(
      await _dio.delete<Map<String, dynamic>>('/api/v1/sme-leave/$leaveId'),
    );
  }

  Future<String> referBack(String leaveId) async {
    return _mapActionResponse(
      await _dio.get<Map<String, dynamic>>('/api/v1/sme-leave-reOpen/$leaveId'),
    );
  }

  Future<String> requestCancellation({
    required String leaveId,
    required String comment,
  }) async {
    return _mapActionResponse(
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/sme-leave-cancellation-req',
        data: {
          'id': leaveId,
          'comments': comment,
        },
      ),
    );
  }

  Future<String> referbackCancellation(String leaveId) async {
    return _mapActionResponse(
      await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-leave-reOpen/$leaveId',
        queryParameters: {'isCancel': 1},
      ),
    );
  }

  Future<LeaveInitialData> getLeaveInitialData() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-leave-formData',
      );
      return _mapLeaveInitialData(response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LeaveSummary> getLeaveSummary(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sme-leave-summary',
        data: payload,
      );
      return _mapLeaveSummary(response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LeaveAvailability> checkLeaveAvailability(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sme-leave-days-calculation',
        data: payload,
      );
      return _mapLeaveAvailability(response.data ?? {});
    } on DioException catch (e) {
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LeaveSaveResponse> saveLeave({
    required int leaveId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final Response<Map<String, dynamic>> response;
      if (leaveId > 0) {
        response = await _dio.put<Map<String, dynamic>>(
          '/api/v1/sme-leave/$leaveId',
          data: payload,
        );
      } else {
        response = await _dio.post<Map<String, dynamic>>(
          '/api/v1/sme-leave',
          data: payload,
        );
      }
      return _mapSaveLeaveResponse(response.data ?? {});
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return _mapSaveLeaveResponse(data);
      }
      throw LeavesApiException(
        _parseErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<String> deleteAttachment(int attachmentId) async {
    return _mapActionResponse(
      await _dio.delete<Map<String, dynamic>>(
        '/api/v1/sme-attachment/$attachmentId',
      ),
    );
  }

  /// Downloads attachment with auth headers (mirrors iOS `downloadAttachment`).
  Future<String> downloadAttachment(LeaveAttachment attachment) async {
    final fileName = _sanitizeFileName(attachment.name ?? 'attachment');
    final link = attachment.link;

    if (link != null && link.isNotEmpty) {
      try {
        return await _downloadToFile(_resolveUrl(link).toString(), fileName);
      } on DioException catch (e) {
        final id = attachment.id;
        if (id == null || id <= 0) {
          throw LeavesApiException(_parseErrorMessage(e));
        }
      }
    }

    final id = attachment.id;
    if (id != null && id > 0) {
      return _downloadHrmsFile(id, fileName);
    }

    throw LeavesApiException('Attachment URL not available.');
  }

  Future<String> _downloadHrmsFile(int id, String fileName) async {
    try {
      final savePath = await _tempFilePath(fileName);
      await _dio.download(
        '/api/v1/downloadHrmsFile',
        savePath,
        queryParameters: {'id': id},
      );
      return savePath;
    } on DioException catch (e) {
      throw LeavesApiException(_parseErrorMessage(e));
    }
  }

  Future<String> _downloadToFile(String url, String fileName) async {
    try {
      final savePath = await _tempFilePath(fileName);
      await _dio.download(url, savePath);
      return savePath;
    } on DioException catch (e) {
      throw LeavesApiException(_parseErrorMessage(e));
    }
  }

  Future<String> _tempFilePath(String fileName) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$fileName';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll('/', '_').trim();
  }

  Uri _resolveUrl(String link) {
    if (link.startsWith('http://') || link.startsWith('https://')) {
      return Uri.parse(link);
    }
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    return Uri.parse(base).resolve(link);
  }

  String _mapActionResponse(Response<Map<String, dynamic>> response) {
    final json = response.data ?? {};
    final success = json['success'] == true;
    final message = json['message'] as String? ?? '';
    if (!success) {
      throw LeavesApiException(
        message.isNotEmpty ? message : 'Something went wrong. Please try again.',
        statusCode: response.statusCode,
      );
    }
    return message;
  }

  List<Leave> _mapLeaveList(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return const [];

    final leaves = <Leave>[];
    for (final record in data) {
      if (record is! Map<String, dynamic>) continue;

      final applicationType = _asInt(record['applicationType']) ?? 0;
      if (applicationType != 1) continue;

      final leaveTypeJson = record['leave_type'];
      final leaveTypeMap =
          leaveTypeJson is Map<String, dynamic> ? leaveTypeJson : null;

      final isHalfDay = _asInt(record['ishalfDay']) ?? 0;
      String? shift;
      if (isHalfDay == 1) {
        shift = (_asInt(record['shift']) ?? 0) == 1 ? 'Morning' : 'Evening';
      }

      leaves.add(
        Leave(
          id: _asInt(record['leaveMasterID']),
          documentCode: record['documentCode'] as String? ?? '',
          confirmedYn: _asInt(record['confirmedYN']) ?? -10,
          approvedYn: _asInt(record['approvedYN']) ?? -10,
          cancelled: _asInt(record['cancelledYN']) ?? 0,
          requestedForCancel: _asInt(record['requestForCancelYN']) ?? 0,
          isHalfDay: isHalfDay,
          shift: shift,
          startDate: record['startDate1'] as String? ?? '',
          endDate: record['endDate1'] as String? ?? '',
          leaveType: LeaveType(
            id: _asInt(leaveTypeMap?['leaveTypeID']),
            name: leaveTypeMap?['description'] as String? ?? '--',
            balance: _asDouble(record['days']) ?? 0,
          ),
        ),
      );
    }

    leaves.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return leaves;
  }

  Leave _mapLeaveDetails(int leaveId, Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw LeavesApiException(
        json['message'] as String? ?? 'Unable to load leave details.',
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw LeavesApiException('Unable to load leave details.');
    }

    final formData = data['formData'];
    final leaveJson = data['leave'];
    if (leaveJson is! Map<String, dynamic>) {
      throw LeavesApiException('Unable to load leave details.');
    }

    final formMap = formData is Map<String, dynamic> ? formData : null;
    final covEmpId = _asInt(leaveJson['coveringEmpID']) ?? 0;
    final leaveTypeId = _asInt(leaveJson['leaveType']) ?? 0;
    final covEmployees = formMap?['covering_emp_drop'];
    final leaveTypes = formMap?['leave_type_drop'];

    LeaveEmployee? coveringEmployee;
    if (covEmpId > 0 && covEmployees is List) {
      for (final record in covEmployees) {
        if (record is! Map<String, dynamic>) continue;
        if ((_asInt(record['value']) ?? 0) == covEmpId) {
          coveringEmployee = LeaveEmployee(
            id: _asInt(record['value']),
            name: record['label'] as String? ?? '',
          );
          break;
        }
      }
    }

    LeaveType? leaveType;
    if (leaveTypeId > 0 && leaveTypes is List) {
      for (final record in leaveTypes) {
        if (record is! Map<String, dynamic>) continue;
        if ((_asInt(record['leaveTypeID']) ?? 0) == leaveTypeId) {
          leaveType = _mapLeaveType(record);
          break;
        }
      }
    }

    final isHalfDay = _asInt(leaveJson['isHalfDay']) ?? 0;
    LeaveShift? shiftType;
    if (isHalfDay == 1) {
      final shift = _asInt(leaveJson['shift']) ?? 0;
      shiftType = LeaveShift(
        id: shift,
        name: shift == 1 ? 'Morning' : 'Evening',
      );
    }

    return Leave(
      id: leaveId,
      documentCode: leaveJson['documentCode'] as String? ?? '',
      comment: leaveJson['comments'] as String? ?? '',
      createdDate: leaveJson['entryDate'] as String? ?? '',
      confirmedYn: _asInt(leaveJson['confirmedYN']) ?? 0,
      approvedYn: _asInt(leaveJson['approvedYN']) ?? -10,
      requestedForCancel: _asInt(leaveJson['requestForCancelYN']) ?? -10,
      cancelled: _asInt(leaveJson['cancelledYN']) ?? 0,
      confirmedBy: leaveJson['confirmedByName'] as String? ?? '',
      confirmedDate: leaveJson['confirmedDate'] as String? ?? '',
      isHalfDay: isHalfDay,
      shiftType: shiftType,
      startDate: leaveJson['startDate'] as String? ?? '',
      endDate: leaveJson['endDate'] as String? ?? '',
      coveringEmployee: coveringEmployee,
      leaveType: leaveType,
      leaveInfo: LeaveInfo(
        requireDelegation: _asDouble(leaveJson['require_delegation']) ?? 0,
      ),
    );
  }

  List<LeaveAttachment> _mapAttachments(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw LeavesApiException(
        json['message'] as String? ?? 'Unable to load attachments.',
      );
    }

    final attachments = json['data'];
    if (attachments is! List) return const [];

    return [
      for (final record in attachments)
        if (record is Map<String, dynamic>)
          LeaveAttachment(
            id: _asInt(record['attachmentID']),
            name: record['myFileName'] as String? ?? '',
            description: record['attachmentDescription'] as String? ?? '',
            link: record['document_url'] as String? ?? '',
          ),
    ];
  }

  List<LeaveApproval> _mapApprovalList(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw LeavesApiException(
        json['message'] as String? ?? 'Unable to load approval details.',
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) return const [];

    final levelList = data['approved'];
    final isRejected = (_asInt(data['reject']) ?? 0) != 0;
    if (levelList is! List) return const [];

    return [
      for (final record in levelList)
        if (record is Map<String, dynamic>)
          LeaveApproval(
            approvalYn: _asInt(record['approvedYN']) ?? 0,
            approvedBy: record['Ename2'] as String? ?? '',
            approvedDate: record['approveDate'] as String? ?? '',
            comment: record['approvedComments'] as String? ?? '',
            isRejected: isRejected,
          ),
    ];
  }

  LeaveInitialData _mapLeaveInitialData(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw LeavesApiException(
        json['message'] as String? ?? 'Unable to load leave form data.',
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw LeavesApiException('Unable to load leave form data.');
    }

    final covEmployees = data['covering_emp_drop'];
    final leaveTypes = data['leave_type_drop'];
    final empDetails = data['employee_department'];
    final empMap = empDetails is Map<String, dynamic> ? empDetails : null;

    final coveringEmployees = <LeaveEmployee>[];
    if (covEmployees is List) {
      for (final record in covEmployees) {
        if (record is! Map<String, dynamic>) continue;
        coveringEmployees.add(
          LeaveEmployee(
            id: _asInt(record['value']),
            name: record['label'] as String? ?? '',
          ),
        );
      }
    }

    final types = <LeaveType>[];
    if (leaveTypes is List) {
      for (final record in leaveTypes) {
        if (record is! Map<String, dynamic>) continue;
        types.add(_mapLeaveType(record));
      }
    }

    final employeeName = data['Ename2'] as String? ??
        formString(data['EmpSecondaryCode']);

    return LeaveInitialData(
      coveringEmployees: coveringEmployees,
      leaveTypes: types,
      coveringEmployeeRequired:
          (_asInt(data['is_covering_employee_required']) ?? 0) != 0,
      empId: _asInt(empMap?['EmpID']) ?? 0,
      employeeDisplayName: employeeName,
    );
  }

  LeaveType _mapLeaveType(Map<String, dynamic> item) {
    return LeaveType(
      id: _asInt(item['leaveTypeID']),
      name: item['label'] as String? ?? '',
      balance: _asDouble(item['balance']) ?? 0,
      policyMasterId: _asInt(item['policyMasterID']),
      leaveGroupId: _asInt(item['leaveGroupID']),
      isAllowsMinus: _asInt(item['allowMinus']),
      isCalendarDays: (_asInt(item['isCalenderDays']) ?? 0) != 0,
      isAttachmentRequired: (_asInt(item['attachmentRequired']) ?? 0) != 0,
      stretchDays: _asInt(item['stretchDays']),
      annualEligibilityDays: _asDouble(item['annualEligibilityDays']),
      isDailyBasisAccrual: _asInt(item['isDailyBasisAccrual']),
      value: _asInt(item['value']),
    );
  }

  LeaveSummary _mapLeaveSummary(Map<String, dynamic> json) {
    final item = json['data'];
    final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
    return LeaveSummary(
      balance: _asDouble(map['balance']),
      balanceDueToDate: _asDouble(map['balanceDueToDate']),
      balanceOnYearEnd: _asDouble(map['balanceOnYearEnd']),
      entitled: _asDouble(map['entitled']),
      finaceYearExist: _asDouble(map['finaceYearExist']),
      isDailyBasisAccrual: _asInt(map['isDailyBasisAccrual']),
      lastYearCFBalance: _asDouble(map['lastYearCFBalance']),
      leaveTaken: _asDouble(map['leaveTaken']),
      noOfDays: _asDouble(map['noOfDays']),
      openingBalance: _asDouble(map['openingBalance']),
      policyMasterId: _asInt(map['policyMasterID']),
    );
  }

  LeaveAvailability _mapLeaveAvailability(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw LeavesApiException(
        json['message'] as String? ?? 'Unable to calculate leave days.',
      );
    }
    final item = json['data'];
    final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
    return LeaveAvailability(
      working: _asDouble(map['workingDays']),
      applied: _asDouble(map['appliedLeave']),
      balance: _asDouble(map['leaveBalance']),
      deductionApplicable: _asDouble(map['isDeductionApplicable']),
    );
  }

  LeaveSaveResponse _mapSaveLeaveResponse(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final message = json['message'] as String? ?? '';
    if (success) {
      return LeaveSaveResponse(success: true, message: message);
    }
    final data = json['data'];
    final covering = data is Map<String, dynamic>
        ? _asInt(data['covering']) ?? 0
        : 0;
    return LeaveSaveResponse(
      success: false,
      message: message,
      leaveCoveringEmpStatus: covering,
    );
  }

  String? formString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _parseErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        final message = decoded['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      } catch (_) {}
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'No internet connection. Please check your network.';
    }

    return error.message ?? 'Something went wrong. Please try again.';
  }
}

class LeavesApiException extends ApiException {
  LeavesApiException(super.message, {this.statusCode});

  final int? statusCode;
}
