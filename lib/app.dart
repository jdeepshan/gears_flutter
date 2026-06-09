import 'package:flutter/material.dart';
import 'package:gears_flutter/core/router/app_router.dart';
import 'package:gears_flutter/core/theme/app_theme.dart';

class GearsErpApp extends StatelessWidget {
  const GearsErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gears ERP',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
