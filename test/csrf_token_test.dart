import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gears_flutter/core/network/csrf_interceptor.dart';
import 'package:gears_flutter/core/network/csrf_token.dart';
import 'package:gears_flutter/core/network/json_whole_number.dart';

void main() {
  const fixedTimestamp = 1700000000;

  test('csrf token matches the CmpRnD payload', () {
    final token = buildCsrfToken(
      method: 'POST',
      encodedPath: '/api/v1/leaves',
      queryParameters: {
        'isCancel': ['1'],
      },
      body: '{"count":1}',
      timestampSeconds: fixedTimestamp,
    );

    expect(
      token,
      'e32aad2ebfe5da49efb4cc4ff5d75b0a791519be8b6116dcee5cbc2780c0bb01|1700000000',
    );
  });

  test('query keys are sorted and empty or null values are dropped', () {
    final token = buildCsrfToken(
      method: 'GET',
      encodedPath: 'api/v1/x',
      queryParameters: {
        'b': ['2'],
        'q': ['a b'],
        'z': ['', 'null', 'NULL'],
        'a': ['1'],
      },
      timestampSeconds: fixedTimestamp,
    );

    expect(
      token,
      'c2a226e644e2817053238a73d23f1dce3f3501cb3db9dc19bc797cdf18943d76|1700000000',
    );
  });

  test('whole number literals become integers outside strings', () {
    expect(
      normalizeWholeNumberLiterals(
        '{"a":1.0,"b":1.5,"c":"1.0","d":-2.0,"e":1e2,"f":"say \\" 1.0"}',
      ),
      '{"a":1,"b":1.5,"c":"1.0","d":-2,"e":100,"f":"say \\" 1.0"}',
    );
  });

  test('interceptor signs the normalized json body', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/'));
    late RequestOptions seen;
    dio.interceptors.add(
      CsrfInterceptor(
        'https://example.com/',
        timestampSeconds: () => fixedTimestamp,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          seen = options;
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: 'ok'),
          );
        },
      ),
    );

    await dio.post<void>(
      '/api/v1/leaves',
      data: {'count': 1.0},
      queryParameters: {'isCancel': 1},
    );

    expect(seen.data, '{"count":1}');
    expect(
      seen.headers[csrfHeaderName],
      'e32aad2ebfe5da49efb4cc4ff5d75b0a791519be8b6116dcee5cbc2780c0bb01|1700000000',
    );
  });

  test('external hosts are not signed', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/'));
    late RequestOptions seen;
    dio.interceptors.add(
      CsrfInterceptor(
        'https://example.com/',
        timestampSeconds: () => fixedTimestamp,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          seen = options;
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: 'ok'),
          );
        },
      ),
    );

    await dio.get<void>('https://s3.amazonaws.com/file.pdf');

    expect(seen.headers[csrfHeaderName], isNull);
  });

  test('empty body is hashed as {} and is not rewritten', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/'));
    late RequestOptions seen;
    dio.interceptors.add(
      CsrfInterceptor(
        'https://example.com/',
        timestampSeconds: () => fixedTimestamp,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          seen = options;
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: 'ok'),
          );
        },
      ),
    );

    await dio.get<void>('/api/v1/x');

    expect(seen.data, isNull);
    expect(
      seen.headers[csrfHeaderName],
      buildCsrfToken(
        method: 'GET',
        encodedPath: 'api/v1/x',
        timestampSeconds: fixedTimestamp,
      ),
    );
  });
}
