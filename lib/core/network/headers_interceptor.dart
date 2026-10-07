import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gears_flutter/core/network/request_host.dart';
import 'package:gears_flutter/core/storage/device_id_storage.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';

class HeadersInterceptor extends QueuedInterceptor {
  HeadersInterceptor(this._baseUrl);

  final String _baseUrl;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // ApiClient Dio instances are bound to one API host. Always attach
      // mobile headers for relative paths (and same-host absolute paths).
      // Do not rely on string contains(_baseUrl) — Dio lowercases the host in
      // options.uri, which can miss a mixed-case stored subdomain.
      if (!isExternalAbsoluteUrl(baseUrl: _baseUrl, path: options.path)) {
        final deviceId = (await DeviceIdStorage.getDeviceId()).trim();
        options.headers['device-id'] = deviceId;
        options.headers['is-mobile'] = '1';

        if (kDebugMode) {
          debugPrint(
            'HeadersInterceptor: device-id=$deviceId '
            'path=${options.path}',
          );
        }

        final authHeader = SessionStorage.authorizationHeader;
        if (authHeader != null) {
          options.headers['Authorization'] = authHeader;

          final selectedCompanyId = SessionStorage.selectedCompanyId;
          if (selectedCompanyId != null) {
            options.headers['selectedCompanyId'] = selectedCompanyId.toString();
          }
        }
      }

      handler.next(options);
    } catch (e, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
          message: 'Failed to attach request headers.',
        ),
      );
    }
  }
}
