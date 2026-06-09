import 'package:dio/dio.dart';
import 'package:gears_flutter/core/storage/device_id_storage.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';

class HeadersInterceptor extends Interceptor {
  HeadersInterceptor(this._baseUrl);

  final String _baseUrl;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isBaseUrl = options.uri.toString().contains(_baseUrl);

    if (isBaseUrl) {
      final deviceId = DeviceIdStorage.cachedDeviceId;
      if (deviceId != null && deviceId.isNotEmpty) {
        options.headers['device-id'] = deviceId;
      }
    }

    if (isBaseUrl) {
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
  }
}
