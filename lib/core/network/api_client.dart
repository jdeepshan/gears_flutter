import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gears_flutter/core/network/headers_interceptor.dart';

class ApiClient {
  ApiClient._();

  static Dio create(String baseUrl) {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'is-mobile': '1'},
      ),
    );

    dio.interceptors.add(HeadersInterceptor(normalized));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (log) => debugPrint(log.toString()),
        ),
      );
    }

    return dio;
  }
}
