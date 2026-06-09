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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.SVG'),
            fit:  BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            /// Center Logo
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 70,
                  right: 45,
                ),
                child: Image.asset(
                  'assets/images/osos_splash_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            /// Bottom Text
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Powered by OSOS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            /// Optional Powered By Image
            /*
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  'assets/images/powered_by_gears.png',
                  height: 12,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }
}
