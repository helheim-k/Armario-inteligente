import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          "Próximamente 🌱",
          style: TextStyle(fontSize: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }
}