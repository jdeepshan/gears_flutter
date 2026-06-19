import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gears_flutter/features/auth/data/azure_ad_test_config.dart';
import 'package:gears_flutter/features/auth/data/models/configuration_info_response.dart';
import 'package:gears_flutter/features/auth/data/models/login_configuration.dart';
import 'package:gears_flutter/features/auth/data/models/login_response.dart';
import 'package:gears_flutter/features/profile/data/models/profile_details_std_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local session flags for navigation (scaffold — replace with token/API later).
class SessionStorage {
  SessionStorage._();

  static const _keySubdomain = 'subdomain_url';
  static const _keyLoggedIn = 'is_logged_in';
  static const _keyIsOnPremise = 'is_on_premise';
  static const _keyPathAd = 'path_ad';
  static const _keyIsAzure = 'is_azure';
  static const _keyLoginType = 'login_type';
  static const _keyLoginConfiguration = 'login_configuration';
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyTokenType = 'token_type';
  static const _keyIsAzureAdUser = 'is_azure_ad_user';
  static const _keySelectedCompanyId = 'selected_company_id';
  static const _keyUserProfileStd = 'user_profile_std';

  static SharedPreferences? _prefs;
  static final Map<String, Object?> _memory = {};
  static bool _useMemory = false;

  /// True when native shared_preferences is unavailable (e.g. hot reload after add).
  static bool get isInMemoryFallback => _useMemory;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _useMemory = false;
    } on MissingPluginException catch (e) {
      _activateMemoryFallback(e);
    } on PlatformException catch (e) {
      _activateMemoryFallback(e);
    }
  }

  static void _activateMemoryFallback(Object error) {
    _useMemory = true;
    _prefs = null;
    debugPrint(
      'SessionStorage: shared_preferences unavailable ($error). '
      'Using in-memory session. Stop the app and run `flutter clean && flutter run` '
      'for persistent storage.',
    );
  }

  static String? _getString(String key) {
    if (_useMemory) {
      return _memory[key] as String?;
    }
    return _prefs!.getString(key);
  }

  static bool? _getBool(String key) {
    if (_useMemory) {
      return _memory[key] as bool?;
    }
    return _prefs!.getBool(key);
  }

  static int? _getInt(String key) {
    if (_useMemory) {
      return _memory[key] as int?;
    }
    return _prefs!.getInt(key);
  }

  static Future<void> _setString(String key, String value) async {
    if (_useMemory) {
      _memory[key] = value;
      return;
    }
    await _prefs!.setString(key, value);
  }

  static Future<void> _setBool(String key, bool value) async {
    if (_useMemory) {
      _memory[key] = value;
      return;
    }
    await _prefs!.setBool(key, value);
  }

  static Future<void> _setInt(String key, int value) async {
    if (_useMemory) {
      _memory[key] = value;
      return;
    }
    await _prefs!.setInt(key, value);
  }

  static Future<void> _remove(String key) async {
    if (_useMemory) {
      _memory.remove(key);
      return;
    }
    await _prefs!.remove(key);
  }

  static Future<void> _clear() async {
    if (_useMemory) {
      _memory.clear();
      return;
    }
    await _prefs!.clear();
  }

  static bool get hasSubdomain => (_getString(_keySubdomain) ?? '').isNotEmpty;

  static String? get subdomainUrl => _getString(_keySubdomain);

  static bool get isOnPremise => _getBool(_keyIsOnPremise) ?? false;

  static String? get pathAd => _getString(_keyPathAd);

  static int get isAzureConfig => _getInt(_keyIsAzure) ?? 0;

  static int get loginType => _getInt(_keyLoginType) ?? 0;

  static LoginConfiguration? get loginConfiguration {
    final json = _getString(_keyLoginConfiguration);
    if (json == null || json.isEmpty) return null;
    return LoginConfiguration.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  static String? get accessToken => _getString(_keyAccessToken);

  static String? get refreshToken => _getString(_keyRefreshToken);

  static String get tokenType => _getString(_keyTokenType) ?? 'Bearer';

  static String? get authorizationHeader {
    final token = accessToken;
    if (token == null || token.isEmpty) return null;
    return '$tokenType $token';
  }

  static int? get selectedCompanyId => _getInt(_keySelectedCompanyId);

  static bool get isAzureAdUser => _getBool(_keyIsAzureAdUser) ?? false;

  static bool get isLoggedIn => _getBool(_keyLoggedIn) ?? false;

  static ProfileDetailsStdResponse? get userProfileStd {
    final json = _getString(_keyUserProfileStd);
    if (json == null || json.isEmpty) return null;
    return ProfileDetailsStdResponse.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  static Future<void> setSubdomain(String url) async {
    await _setString(_keySubdomain, url.trim());
  }

  static Future<void> setIsOnPremise(bool value) async {
    await _setBool(_keyIsOnPremise, value);
  }

  static Future<void> setConfigurationInfo(ConfigurationData data) async {
    final pathAd = AzureAdTestConfig.enabled
        ? AzureAdTestConfig.pathAd
        : (data.pathAD ?? '');
    await _setString(_keyPathAd, pathAd);

    final isAzure = AzureAdTestConfig.enabled ? 1 : data.isAzure;

    if (isAzure == 1) {
      await _setInt(_keyIsAzure, 1);
      await _setInt(_keyLoginType, data.primaryLoginType ?? 0);
      await _remove(_keyLoginConfiguration);
    } else if (!AzureAdTestConfig.enabled && data.isKeycloakLogin) {
      await _setInt(_keyIsAzure, 0);
      await _setInt(_keyLoginType, 4);
      final config = data.loginConfiguration;
      if (config != null) {
        await _setString(
          _keyLoginConfiguration,
          jsonEncode(config.toJson()),
        );
      } else {
        await _remove(_keyLoginConfiguration);
      }
    } else {
      await _setInt(_keyIsAzure, 0);
      await _setInt(_keyLoginType, data.primaryLoginType ?? 0);
      await _remove(_keyLoginConfiguration);
    }
  }

  static Future<void> clearSubdomain() async {
    await _remove(_keySubdomain);
    await _remove(_keyIsOnPremise);
    await _remove(_keyPathAd);
    await _remove(_keyIsAzure);
    await _remove(_keyLoginType);
    await _remove(_keyLoginConfiguration);
  }

  static Future<void> setAccessToken(String token) async {
    await _setString(_keyAccessToken, token);
  }

  static Future<void> setLoginTokens(LoginResponse response) async {
    final accessToken = response.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Login failed. No access token received.');
    }

    await _setString(_keyAccessToken, accessToken);
    await _setString(_keyTokenType, response.tokenType ?? 'Bearer');

    final refreshToken = response.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _setString(_keyRefreshToken, refreshToken);
    } else {
      await _remove(_keyRefreshToken);
    }
  }

  static Future<void> setIsAzureAdUser(bool value) async {
    await _setBool(_keyIsAzureAdUser, value);
  }

  static Future<void> setUserProfileStd(
    ProfileDetailsStdResponse profile,
  ) async {
    await _setString(_keyUserProfileStd, jsonEncode(profile.toJson()));

    final companyId = profile.data?.employee?.company?.companyId;
    await setSelectedCompanyId(companyId);
  }

  static Future<void> setSelectedCompanyId(int? companyId) async {
    if (companyId == null) {
      await _remove(_keySelectedCompanyId);
      return;
    }
    await _setInt(_keySelectedCompanyId, companyId);
  }

  static Future<void> setLoggedIn(bool value) async {
    await _setBool(_keyLoggedIn, value);
  }

  static Future<void> clearSession() async {
    await _remove(_keyLoggedIn);
    await _remove(_keyAccessToken);
    await _remove(_keyRefreshToken);
    await _remove(_keyTokenType);
    await _remove(_keyIsAzureAdUser);
    await _remove(_keySelectedCompanyId);
    await _remove(_keyUserProfileStd);
  }

  static Future<void> clearAll() async {
    await _clear();
  }
}
