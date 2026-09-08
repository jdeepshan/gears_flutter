import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gears_flutter/core/network/api_timing_interceptor.dart';
import 'package:gears_flutter/core/network/headers_interceptor.dart';

class ApiClient {
  ApiClient._();

  static Dio create(String baseUrl) {
    // Normalize host to lowercase so header/host matching stays consistent.
    final parsed = Uri.tryParse(baseUrl.trim());
    final hostNormalized = parsed != null && parsed.hasScheme && parsed.host.isNotEmpty
        ? parsed.replace(host: parsed.host.toLowerCase()).toString()
        : baseUrl.trim();
    final normalized =
        hostNormalized.endsWith('/') ? hostNormalized : '$hostNormalized/';

    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'is-mobile': '1'},
      ),
    );

    dio.interceptors.add(HeadersInterceptor(normalized));
    // Release-safe latency logs (same format as CMP): adb logcat -s flutter | grep API_MS
    dio.interceptors.add(ApiTimingInterceptor());

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
