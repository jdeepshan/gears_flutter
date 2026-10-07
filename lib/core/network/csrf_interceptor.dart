import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gears_flutter/core/network/csrf_token.dart';
import 'package:gears_flutter/core/network/json_whole_number.dart';
import 'package:gears_flutter/core/network/request_host.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';

/// Adds `X-Csrf-Token` and rewrites JSON bodies so whole numbers are integers.
class CsrfInterceptor extends Interceptor {
  CsrfInterceptor(this._baseUrl, {int Function()? timestampSeconds})
    : _timestampSeconds = timestampSeconds ?? _clockTimestamp;

  final String _baseUrl;
  final int Function() _timestampSeconds;

  static int _clockTimestamp() {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds + SessionStorage.serverTimeDiffSeconds;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      if (!isExternalAbsoluteUrl(baseUrl: _baseUrl, path: options.path)) {
        final body = _bodyForToken(options);
        options.headers[csrfHeaderName] = buildCsrfToken(
          method: options.method,
          encodedPath: _encodedPath(options.uri),
          queryParameters: options.uri.queryParametersAll,
          body: body,
          timestampSeconds: _timestampSeconds(),
        );
      }
      handler.next(options);
    } catch (e, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
          message: 'Failed to sign the request.',
        ),
      );
    }
  }

  /// JSON maps and lists are replaced with the normalized text that is hashed.
  /// Empty and non-JSON bodies are hashed as `{}` and left unchanged.
  String _bodyForToken(RequestOptions options) {
    final data = options.data;
    if (data == null ||
        data is FormData ||
        data is Stream ||
        data is Uint8List) {
      return '{}';
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return '{}';
      if (!_isJsonContent(options)) return trimmed;
      final normalized = normalizeWholeNumberLiterals(trimmed);
      options.data = normalized;
      return normalized;
    }

    if (data is Map || data is List) {
      final normalized = jsonBodyForWire(data);
      options.data = normalized;
      options.contentType ??= Headers.jsonContentType;
      return normalized;
    }

    return '{}';
  }

  bool _isJsonContent(RequestOptions options) {
    final type = options.contentType;
    if (type == null || type.isEmpty) return true;
    return type.toLowerCase().contains('application/json');
  }

  String _encodedPath(Uri uri) {
    if (uri.pathSegments.isEmpty) return '';
    return uri.pathSegments.map(Uri.encodeComponent).join('/');
  }
}
