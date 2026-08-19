import 'package:flutter/material.dart';
import 'package:gears_flutter/core/router/routes.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    if (SessionStorage.isLoggedIn) {
      context.go(AppRoutes.homeProfile);
    } else if (SessionStorage.hasSubdomain) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.subdomain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 70,
                right: 45,
              ),
              child: Image.asset(
                'assets/images/osos_splash_logo.png',
                color: colorScheme.onPrimary,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Powered by OSOS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
