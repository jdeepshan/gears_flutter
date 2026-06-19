import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gears_flutter/core/network/api_client.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/features/approvals/data/models/approve_doc_response.dart';
import 'package:gears_flutter/features/approvals/data/models/attachments_response.dart';
import 'package:gears_flutter/features/approvals/data/models/claim_std_details_response.dart';
import 'package:gears_flutter/features/approvals/data/models/hrms_approvals_std_response.dart';
import 'package:gears_flutter/features/approvals/data/models/leave_std_details_response.dart';

class ApprovalsApi {
  ApprovalsApi(String baseUrl) : _dio = ApiClient.create(baseUrl);

  final Dio _dio;

  Future<HrmsApprovalsStdResponse> getHrmsApprovalsStd() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-profile-pending-approvals',
      );
      return HrmsApprovalsStdResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<LeaveStdDetailsResponse> getLeaveStdDetails(
    int leaveMasterId, {
    bool isFromApproval = true,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-leave/$leaveMasterId',
        queryParameters: {'isFromApproval': isFromApproval},
      );
      return LeaveStdDetailsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<ClaimStdDetailsResponse> getExpenseClaimStdDetails(
    int claimMasterId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-expense-claim-print/$claimMasterId',
      );
      return ClaimStdDetailsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<AttachmentsResponse> getDocumentStdAttachments(
    int masterId,
    String documentId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sme-attachment/$masterId/$documentId',
      );
      return AttachmentsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<ApproveDocResponse> submitLeaveStdApproval({
    required int status,
    required String comment,
    required int documentAutoId,
    required int approvalLevel,
    required bool isCancellation,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sme-leavesApprove',
        data: {
          'app_status': status,
          'app_comments': comment,
          'id': documentAutoId.toString(),
          'levelNo': approvalLevel.toString(),
          'fromCancellation': isCancellation ? 1 : 0,
        },
      );
      return ApproveDocResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<ApproveDocResponse> submitClaimStdApproval({
    required int documentAutoId,
    required int status,
    required String comment,
    required int approvalLevel,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sme-expense-claim-approve',
        data: {
          'id': documentAutoId.toString(),
          'status': status,
          'comments': comment,
          'level': approvalLevel,
        },
      );
      return ApproveDocResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
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

    return error.message ?? 'Something went wrong. Please try again.';
  }
}
