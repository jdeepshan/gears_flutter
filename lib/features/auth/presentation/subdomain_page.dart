import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gears_flutter/core/storage/device_id_storage.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/auth/data/auth_api.dart';
import 'package:go_router/go_router.dart';

class SubdomainPage extends StatefulWidget {
  const SubdomainPage({super.key});

  @override
  State<SubdomainPage> createState() => _SubdomainPageState();
}

class _SubdomainPageState extends State<SubdomainPage> {
  final _formKey = GlobalKey<FormState>();
  final _subdomainController = TextEditingController();

  bool _isLoading = false;
  bool _isCloud = true;

  @override
  void dispose() {
    _subdomainController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final input = _subdomainController.text.trim();
    final baseUrl = _isCloud
        ? 'https://$input.gears-int.com'
        : 'https://$input';

    try {
      final response = await AuthApi(baseUrl).getConfigurationInfo();

      if (response.data == null) {
        throw ApiException(
          response.message ?? 'Unable to load server configuration.',
        );
      }

      await SessionStorage.setSubdomain(baseUrl);
      await SessionStorage.setIsOnPremise(!_isCloud);
      await SessionStorage.setConfigurationInfo(response.data!);

      if (!mounted) return;

      final message = response.message;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      context.go(AppRoutes.login);
    } on ApiException catch (e) {
      await SessionStorage.clearSubdomain();
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      await SessionStorage.clearSubdomain();
      if (!mounted) return;
      _showError(
        !_isCloud
            ? 'A server with the specified hostname could not be found'
            : 'Please recheck your subdomain provided by your company',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onCopyDeviceId() async {
    final deviceId = await DeviceIdStorage.getDeviceId();
    await Clipboard.setData(ClipboardData(text: deviceId));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device ID copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          /// Toggle Group
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  label: Text('Cloud'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('On-Premise'),
                                ),
                              ],
                              selected: {_isCloud},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _isCloud = value.first;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text.rich(
                            TextSpan(
                              text: 'Please enter your subdomain provided by the \n company. (',
                              children: [
                                TextSpan(
                                  text: 'Red',
                                  style: TextStyle(color: Color(0xFFFF0000)),
                                ),
                                TextSpan(
                                  text: ' highlighted text as shown below)',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _isCloud
                                ? 'https://xxxx.gears-int.com'
                                : 'https://your-server-address',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Subdomain Input
                          TextFormField(
                            controller: _subdomainController,
                            decoration: const InputDecoration(
                              labelText: 'Subdomain',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Subdomain is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Save Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _onSave,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: primaryColor,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text('Save'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Copy Device ID Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _onCopyDeviceId,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Device ID'),
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Powered by OSOS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
}
