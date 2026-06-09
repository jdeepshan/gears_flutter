import 'package:flutter/material.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/auth/data/auth_api.dart';
import 'package:gears_flutter/features/auth/data/azure_auth_config.dart';
import 'package:gears_flutter/features/auth/data/azure_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:msal_auth/msal_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _isAzureLogin => SessionStorage.isAzureConfig == 1;

  bool get _isKeycloakLogin => SessionStorage.loginType == 4;

  bool get _isSsoEnabled => _isAzureLogin || _isKeycloakLogin;

  bool get _isPasswordLoginEnabled => !_isAzureLogin && !_isKeycloakLogin;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _showMessage('Please enter the subdomain and try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthApi(baseUrl).login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (response.success == false) {
        throw ApiException('Login failed. Please check your credentials.');
      }

      await SessionStorage.setLoginTokens(response);
      await SessionStorage.setIsAzureAdUser(false);
      await SessionStorage.setLoggedIn(true);

      if (!mounted) return;
      context.go(AppRoutes.homeProfile);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSsoLogin() async {
    if (_isKeycloakLogin) {
      _showMessage('Keycloak sign-in is not yet supported on this platform.');
      return;
    }

    if (!_isAzureLogin) return;

    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _showMessage('Please enter the subdomain and try again.');
      return;
    }

    final azureConfig = AzureAuthConfig.forPathAd(SessionStorage.pathAd);
    if (azureConfig == null) {
      _showMessage('Sign in configurations not found for your company.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResult = await AzureAuthService(azureConfig).signIn();
      final apiResponse = await AuthApi(baseUrl).loginWithADToken(
        token: authResult.accessToken,
        username: authResult.account.username,
      );

      final accessToken = apiResponse.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException('Login failed. No access token received.');
      }

      await SessionStorage.setAccessToken(accessToken);
      await SessionStorage.setIsAzureAdUser(true);
      await SessionStorage.setLoggedIn(true);

      if (!mounted) return;
      context.go(AppRoutes.homeProfile);
    } on MsalUserCancelException {
      // User dismissed the Azure sign-in prompt.
    } on MsalException catch (e) {
      _showMessage(e.message);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onChangeSubdomain() async {
    await SessionStorage.clearSession();
    if (!mounted) return;
    context.go(AppRoutes.subdomain);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subdomain = SessionStorage.subdomainUrl ?? '';
    final ssoLabel = _isKeycloakLogin
        ? 'Sign in with Keycloak'
        : 'Sign in with Microsoft';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (subdomain.isNotEmpty) ...[
                  Chip(
                    avatar: const Icon(Icons.domain, size: 18),
                    label: Text(subdomain),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _usernameController,
                  enabled: _isPasswordLoginEnabled && !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (!_isPasswordLoginEnabled) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: _isPasswordLoginEnabled && !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: _isPasswordLoginEnabled
                          ? () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            }
                          : null,
                    ),
                  ),
                  obscureText: _obscurePassword,
                  onFieldSubmitted: _isPasswordLoginEnabled ? (_) => _onLogin() : null,
                  validator: (value) {
                    if (!_isPasswordLoginEnabled) return null;
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                if (_isPasswordLoginEnabled) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showMessage('Forgot password — coming soon');
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],
                const Spacer(),
                if (_isSsoEnabled)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _onSsoLogin,
                    icon: const Icon(Icons.login),
                    label: Text(ssoLabel),
                  ),
                if (_isSsoEnabled) const SizedBox(height: 12),
                if (_isPasswordLoginEnabled)
                  FilledButton(
                    onPressed: _isLoading ? null : _onLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _onChangeSubdomain,
                  child: const Text('Edit Subdomain'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
