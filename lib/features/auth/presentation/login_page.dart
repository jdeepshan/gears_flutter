import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/device_id_storage.dart';
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
  String? _deviceId;

  bool get _isKeycloakLogin => SessionStorage.loginType == 4;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await DeviceIdStorage.getDeviceId();
    if (!mounted) return;
    setState(() => _deviceId = deviceId);
  }

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
        throw ApiException(
          response.message?.isNotEmpty == true
              ? response.message!
              : 'Login failed. Please check your credentials.',
        );
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

  Future<void> _onAdLogin() async {
    if (_isKeycloakLogin) {
      _showMessage('Keycloak sign-in is not yet supported on this platform.');
      return;
    }

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
        throw ApiException(
          apiResponse.message?.isNotEmpty == true
              ? apiResponse.message!
              : 'Login failed. No access token received.',
        );
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

  Future<void> _onCopyDeviceId() async {
    final deviceId = _deviceId ?? await DeviceIdStorage.getDeviceId();
    await Clipboard.setData(ClipboardData(text: deviceId));
    if (!mounted) return;
    setState(() => _deviceId = deviceId);
    _showMessage('Device ID copied: $deviceId');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _connectedSubdomain(String subdomain, Color primaryColor) {
    final display = subdomain.endsWith('/')
        ? subdomain.substring(0, subdomain.length - 1)
        : subdomain;

    final hostStart = display.indexOf('://');
    final highlightStart = hostStart >= 0 ? hostStart + 3 : 0;
    final highlightEnd = display.indexOf('.', highlightStart);
    if (highlightEnd <= highlightStart) {
      return Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            const TextSpan(text: 'Connected '),
            TextSpan(
              text: display,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        children: [
          const TextSpan(text: 'Connected '),
          TextSpan(text: display.substring(0, highlightStart)),
          TextSpan(
            text: display.substring(highlightStart, highlightEnd),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: display.substring(highlightEnd)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final subdomain = SessionStorage.subdomainUrl ?? '';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/splash_background.svg',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 24,
                      ),
                      child: Image.asset(
                        'assets/images/osos_splash_logo.png',
                        color: Colors.white,
                        fit: BoxFit.contain,
                        height: 72,
                      ),
                    ),
                    Card(
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (subdomain.isNotEmpty)
                                _connectedSubdomain(subdomain, primaryColor)
                              else
                                const Text(
                                  'Connected Not set',
                                  style: TextStyle(fontSize: 13),
                                ),
                              if (_deviceId != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        'Device ID: $_deviceId',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy Device ID',
                                      onPressed: _onCopyDeviceId,
                                      icon: const Icon(Icons.copy, size: 18),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 27),
                              TextFormField(
                                controller: _usernameController,
                                enabled: !_isLoading,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Username is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () =>
                                            _obscurePassword = !_obscurePassword,
                                      );
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                onFieldSubmitted: (_) => _onLogin(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: _isLoading ? null : _onLogin,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _isLoading ? null : _onAdLogin,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  _isKeycloakLogin
                                      ? 'LOGIN WITH KEYCLOAK'
                                      : 'LOGIN WITH AD',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed:
                                    _isLoading ? null : _onChangeSubdomain,
                                icon: const Icon(Icons.link, size: 18),
                                label: const Text(
                                  'EDIT SUBDOMAIN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Powered by '),
                                    TextSpan(
                                      text: 'OSOS',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
