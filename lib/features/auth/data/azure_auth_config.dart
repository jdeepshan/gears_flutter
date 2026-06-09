import 'package:flutter/foundation.dart';
import 'package:gears_flutter/features/auth/data/azure_ad_test_config.dart';

class AzureAuthConfig {
  const AzureAuthConfig({
    required this.configFilePath,
    required this.androidClientId,
    required this.iosClientId,
    required this.tenantId,
    required this.androidRedirectUri,
  });

  final String configFilePath;
  final String androidClientId;
  final String iosClientId;
  final String tenantId;
  final String androidRedirectUri;

  static const _releaseRedirectUri =
      'msauth://com.gears.gearserp/TGBOUBcsIFWTTNYPXwfVjmPiw4w%3D';

  static AzureAuthConfig? forPathAd(String? pathAd) {
    final resolvedPathAd = AzureAdTestConfig.enabled
        ? AzureAdTestConfig.pathAd
        : pathAd;
    final key = _normalizePathAd(resolvedPathAd);
    if (key == null) return null;

    // osos-qa is registered in Azure with the release redirect URI
    // (same as native Android release + research_flutter).
    if (key == 'osos-qa') {
      return _releaseConfigs[key];
    }

    return kDebugMode ? _debugConfigs[key] : _releaseConfigs[key];
  }

  static String? _normalizePathAd(String? pathAd) {
    if (pathAd == null || pathAd.isEmpty) return null;

    switch (pathAd) {
      case 'gutech':
        return 'gutech';
      case 'osos-qa':
        return 'osos-qa';
      // case 'hrms-portal-qa2':
      //   return 'osos-qa';
      default:
        return null;
    }
  }

  static const _iosClientId = 'ce02c371-9f13-4a70-9964-9f30a9fae434';

  static final Map<String, AzureAuthConfig> _debugConfigs = {
    'gutech': AzureAuthConfig(
      configFilePath: 'assets/msal/gutech_debug.json',
      androidClientId: '3d32603e-bc68-4214-8f5d-4617c0e6e17a',
      iosClientId: _iosClientId,
      tenantId: 'common',
      androidRedirectUri:
          'msauth://com.gears.gearserp/VyykCdW83cnLrpejYNWgjEYIkME%3D',
    ),
    'osos-qa': AzureAuthConfig(
      configFilePath: 'assets/msal/osos_qa_debug.json',
      androidClientId: 'e4051105-8bd7-4ddc-bad7-66a68f75b530',
      iosClientId: _iosClientId,
      tenantId: 'organizations',
      androidRedirectUri:
          'msauth://com.gears.gearserp/2n0dlOJsFBKW%2F38eBZEi9ggSwqo%3D',
    ),
  };

  static final Map<String, AzureAuthConfig> _releaseConfigs = {
    'gutech': AzureAuthConfig(
      configFilePath: 'assets/msal/gutech_release.json',
      androidClientId: '8c86c17d-d0c5-482e-a339-079b79e9317f',
      iosClientId: _iosClientId,
      tenantId: '7d922bb1-6c13-46b3-abcf-4663db002d60',
      androidRedirectUri: _releaseRedirectUri,
    ),
    'osos-qa': AzureAuthConfig(
      configFilePath: 'assets/msal/osos_qa_release.json',
      androidClientId: 'e4051105-8bd7-4ddc-bad7-66a68f75b530',
      iosClientId: _iosClientId,
      tenantId: 'f46931c3-8ef0-4fbd-8ec4-ecbfbbff0575',
      androidRedirectUri: _releaseRedirectUri,
    ),
  };
}
