import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdStorage {
  DeviceIdStorage._();

  static const _keyDeviceId = 'generated_uuid';

  static SharedPreferences? _prefs;
  static final Map<String, Object?> _memory = {};
  static bool _useMemory = false;
  static String? _cachedDeviceId;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _useMemory = false;
    } on MissingPluginException catch (e) {
      _activateMemoryFallback(e);
    } on PlatformException catch (e) {
      _activateMemoryFallback(e);
    }

    await getDeviceId();
  }

  static void _activateMemoryFallback(Object error) {
    _useMemory = true;
    _prefs = null;
    debugPrint(
      'DeviceIdStorage: shared_preferences unavailable ($error). '
      'Using in-memory device id.',
    );
  }

  static String? _readStoredId() {
    if (_useMemory) {
      return _memory[_keyDeviceId] as String?;
    }
    return _prefs!.getString(_keyDeviceId);
  }

  static Future<void> _writeStoredId(String value) async {
    if (_useMemory) {
      _memory[_keyDeviceId] = value;
      return;
    }
    await _prefs!.setString(_keyDeviceId, value);
  }

  static String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}'
        '${hex(bytes[14])}${hex(bytes[15])}';
  }

  static String? get cachedDeviceId => _cachedDeviceId ?? _readStoredId();

  static Future<String> getDeviceId() async {
    final cached = _cachedDeviceId;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final stored = _readStoredId();
    if (stored != null && stored.isNotEmpty) {
      _cachedDeviceId = stored;
      return stored;
    }

    final generated = _generateUuid();
    await _writeStoredId(generated);
    _cachedDeviceId = generated;
    return generated;
  }
}
