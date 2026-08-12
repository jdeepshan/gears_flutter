import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gears_flutter/core/network/api_client.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/features/profile/data/models/profile_details_std_response.dart';

class ProfileApi {
  ProfileApi(String baseUrl) : _dio = ApiClient.create(baseUrl);

  final Dio _dio;

  Future<ProfileDetailsStdResponse> getProfileDetailsStd() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'api/v1/getSmeProfilePersonalDetails',
      );
      return ProfileDetailsStdResponse.fromJson(response.data!);
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
