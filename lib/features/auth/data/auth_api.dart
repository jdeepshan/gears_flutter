import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gears_flutter/core/network/api_client.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/features/auth/data/models/configuration_info_response.dart';
import 'package:gears_flutter/features/auth/data/models/login_response.dart';
import 'package:gears_flutter/features/auth/data/models/login_with_ad_token_response.dart';

class AuthApi {
  AuthApi(String baseUrl) : _dio = ApiClient.create(baseUrl);

  final Dio _dio;

  Future<ConfigurationInfoResponse> getConfigurationInfo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/getConfigurationInfo',
      );
      return ConfigurationInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/login',
        data: {
          'grant_type': 'password',
          'username': username,
          'password': password,
          'scope': '',
        },
      );
      return LoginResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_parseErrorMessage(e));
    }
  }

  Future<LoginWithAdTokenResponse> loginWithADToken({
    required String token,
    String? username,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/oauth/login_with_token',
        data: {
          'username': username,
          'token': token,
          'isAzure': true,
        },
      );
      return LoginWithAdTokenResponse.fromJson(response.data!);
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

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Unable to connect to the server. Please check your subdomain.';
    }

    return error.message ?? 'Something went wrong. Please try again.';
  }
}
