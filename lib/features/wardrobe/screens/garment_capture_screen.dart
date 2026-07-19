import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import 'garment_confirmation_screen.dart';

class GarmentCaptureScreen extends StatefulWidget {
  const GarmentCaptureScreen({super.key});

  @override
  State<GarmentCaptureScreen> createState() => _GarmentCaptureScreenState();
}

class _GarmentCaptureScreenState extends State<GarmentCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (photo == null || !mounted) return;

    final Uint8List bytes = await photo.readAsBytes();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GarmentConfirmationScreen(imageBytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Registrar prenda"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checkroom, size: 80, color: AppColors.pinkDark),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Tomar foto"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text("Elegir de galería"),
            ),
          ],
        ),
      ),
    );
  }
}