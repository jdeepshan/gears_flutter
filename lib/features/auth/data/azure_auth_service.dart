import 'dart:io';

import 'package:gears_flutter/features/auth/data/azure_auth_config.dart';
import 'package:msal_auth/msal_auth.dart';

class AzureAuthService {
  AzureAuthService(this._config);

  final AzureAuthConfig _config;
  SingleAccountPca? _pca;

  static const _scopes = <String>['User.Read'];

  Future<AuthenticationResult> signIn() async {
    final pca = await _getPca();
    return pca.acquireToken(
      scopes: _scopes,
      prompt: Prompt.login,
      authority: Platform.isAndroid
          ? 'https://login.microsoftonline.com/${_config.tenantId}'
          : null,
    );
  }

  Future<SingleAccountPca> _getPca() async {
    final existing = _pca;
    if (existing != null) return existing;

    final clientId =
        Platform.isIOS ? _config.iosClientId : _config.androidClientId;

    final pca = await SingleAccountPca.create(
      clientId: clientId,
      androidConfig: AndroidConfig(
        configFilePath: _config.configFilePath,
        redirectUri: _config.androidRedirectUri,
      ),
      appleConfig: AppleConfig(
        authorityType: AuthorityType.aad,
        authority: 'https://login.microsoftonline.com/${_config.tenantId}',
        broker: Broker.msAuthenticator,
      ),
    );

    _pca = pca;
    return pca;
  }
}
