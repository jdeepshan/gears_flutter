import 'dart:convert';

import 'package:crypto/crypto.dart';

const csrfHeaderName = 'X-Csrf-Token';

/// Same shared secret as CmpRnD `NetworkConstants.CSRF_SECRET_KEY`.
const csrfSecretKey =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// `hash|timestamp`, matching CmpRnD `CsrfPlugin`.
///
/// [encodedPath] is the URL path without a leading slash. Query keys are
/// sorted, empty values and the literal `null` are dropped, and both sides
/// are encoded like JavaScript `encodeURIComponent`.
String buildCsrfToken({
  required String method,
  required String encodedPath,
  Map<String, List<String>> queryParameters = const {},
  String body = '',
  required int timestampSeconds,
  String secretKey = csrfSecretKey,
}) {
  final path = encodedPath.startsWith('/')
      ? encodedPath.substring(1)
      : encodedPath;
  final query = _sortedQuery(queryParameters);
  final completePath = query.isEmpty ? path : '$path?$query';
  final normalizedBody = body.trim().isEmpty ? '{}' : body.trim();
  final requestString = '$normalizedBody|$completePath|${method.toLowerCase()}';
  final payload =
      '${base64Encode(utf8.encode(requestString))}|$timestampSeconds';
  final hash = Hmac(
    sha256,
    utf8.encode(secretKey),
  ).convert(utf8.encode(payload)).toString();
  return '$hash|$timestampSeconds';
}

String _sortedQuery(Map<String, List<String>> queryParameters) {
  final keys = queryParameters.keys.toList()..sort();
  final parts = <String>[];
  for (final key in keys) {
    for (final value in queryParameters[key] ?? const []) {
      if (value.isEmpty || value.toLowerCase() == 'null') continue;
      parts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
    }
  }
  return parts.join('&');
}
