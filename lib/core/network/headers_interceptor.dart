import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gears_flutter/core/storage/device_id_storage.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';

class HeadersInterceptor extends QueuedInterceptor {
  HeadersInterceptor(this._baseUrl);

  final String _baseUrl;

  /// True for absolute URLs that are outside this API host (e.g. S3).
  bool _isExternalAbsoluteUrl(RequestOptions options) {
    final path = options.path;
    if (!path.startsWith(RegExp(r'https?:', caseSensitive: false))) {
      return false;
    }

    final requestHost = Uri.tryParse(path)?.host.toLowerCase();
    final apiHost = Uri.tryParse(_baseUrl)?.host.toLowerCase();
    if (requestHost == null || apiHost == null || apiHost.isEmpty) {
      return true;
    }
    return requestHost != apiHost;
  }

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
      if (!_isExternalAbsoluteUrl(options)) {
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
