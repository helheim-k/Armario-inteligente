import 'package:flutter/material.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class ArmarioInteligenteApp extends StatelessWidget {
  const ArmarioInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Armario Inteligente',
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
    );
  }
}