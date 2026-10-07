import 'dart:convert';

/// Write-side equivalent of CmpRnD `SerializeOnlyNumberConverter`.
///
/// Whole-number JSON literals are emitted as integers (`1.0` → `1`) so the
/// body hashed for `X-Csrf-Token` matches the bytes sent on the wire.
String normalizeWholeNumberLiterals(String json) {
  final result = StringBuffer();
  var index = 0;
  var inString = false;

  while (index < json.length) {
    final char = json[index];
    if (inString) {
      result.write(char);
      if (char == '\\' && index + 1 < json.length) {
        result.write(json[index + 1]);
        index += 2;
        continue;
      }
      if (char == '"') inString = false;
      index++;
      continue;
    }

    if (char == '"') {
      inString = true;
      result.write(char);
      index++;
      continue;
    }

    if (char == '-' || _isDigit(char)) {
      final start = index;
      if (json[index] == '-') index++;
      while (index < json.length && _isJsonNumberChar(json[index])) {
        index++;
      }
      result.write(_wholeNumberOrOriginal(json.substring(start, index)));
      continue;
    }

    result.write(char);
    index++;
  }

  return result.toString();
}

/// Encodes a JSON object or array, writing whole numbers as integers.
String jsonBodyForWire(Object data) {
  return normalizeWholeNumberLiterals(jsonEncode(data));
}

bool _isDigit(String char) {
  final code = char.codeUnitAt(0);
  return code >= 48 && code <= 57;
}

bool _isJsonNumberChar(String char) =>
    _isDigit(char) ||
    char == '.' ||
    char == 'e' ||
    char == 'E' ||
    char == '+' ||
    char == '-';

String _wholeNumberOrOriginal(String token) {
  if (!token.contains('.') && !token.contains('e') && !token.contains('E')) {
    return token;
  }

  final value = double.tryParse(token);
  if (value == null || !value.isFinite || value != value.roundToDouble()) {
    return token;
  }

  // Signed 64-bit range. 2^63 is the first integer that does not fit.
  if (value >= 9223372036854775808.0 || value < -9223372036854775808.0) {
    return token;
  }

  return value.toInt().toString();
}
