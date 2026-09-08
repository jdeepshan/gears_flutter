import 'package:dio/dio.dart';

/// Logs client-seen HTTP latency for framework comparison (works in release).
///
/// Logcat: `adb logcat -s flutter | grep API_MS`
/// Format: `API_MS <METHOD> <path> <ms>` or `API_MS ERR <METHOD> <path> <ms>`
class ApiTimingInterceptor extends Interceptor {
  static const _startKey = 'api_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, ok: true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, ok: false);
    handler.next(err);
  }

  void _log(RequestOptions options, {required bool ok}) {
    final start = options.extra[_startKey];
    if (start is! int) return;
    final ms = DateTime.now().millisecondsSinceEpoch - start;
    final path = options.uri.path.isEmpty ? options.path : options.uri.path;
    final tag = ok ? 'API_MS' : 'API_MS ERR';
    // print survives release; shows under flutter logcat tag
    // ignore: avoid_print
    print('$tag ${options.method} $path $ms');
  }
}
