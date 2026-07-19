import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/wardrobe_controller.dart';
import '../services/garment_detection_service.dart';

class GarmentConfirmationScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const GarmentConfirmationScreen({super.key, required this.imageBytes});

  @override
  State<GarmentConfirmationScreen> createState() => _GarmentConfirmationScreenState();
}

class _GarmentConfirmationScreenState extends State<GarmentConfirmationScreen> {
  final WardrobeController _wardrobeController = WardrobeController();
  final GarmentDetectionService _detectionService = GarmentDetectionService();

  final _typeController = TextEditingController();
  final _colorController = TextEditingController();
  final Set<String> _selectedSeasons = {};

  bool _isSaving = false;
  bool _isDetecting = true;
  String? _detectionError;

  final List<String> temporadas = [
    'Primavera',
    'Verano',
    'Otoño',
    'Invierno',
  ];

  @override
  void initState() {
    super.initState();
    _detectGarment();
  }

  Future<void> _detectGarment() async {
    setState(() {
      _isDetecting = true;
      _detectionError = null;
    });

    try {
      final detected = await _detectionService.detectGarment(widget.imageBytes);

      if (!mounted) return;
      setState(() {
        if (detected.type != null && detected.type!.isNotEmpty) {
          _typeController.text = detected.type!;
        }
        if (detected.colorPrimary != null && detected.colorPrimary!.isNotEmpty) {
          _colorController.text = detected.colorPrimary!;
        }
      });
    } catch (e) {
      debugPrint('ERROR DETECCIÓN: $e');
      if (!mounted) return;
      setState(() => _detectionError = 'No se pudo autodetectar. Llena los campos manualmente.');
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_typeController.text.trim().isEmpty || _colorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa tipo y color antes de guardar.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _wardrobeController.registerGarment(
        imageBytes: widget.imageBytes,
        type: _typeController.text.trim(),
        colorPrimary: _colorController.text.trim(),
        seasons: _selectedSeasons.toList(),
      );

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo guardar la prenda. Intenta de nuevo.")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(widget.imageBytes, height: 260, fit: BoxFit.cover, width: double.infinity),
                ),
                if (_isDetecting)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              "Detectando prenda...",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_detectionError != null) ...[
              const SizedBox(height: 8),
              Text(_detectionError!, style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tipo de prenda", style: TextStyle(fontWeight: FontWeight.w500)),
                if (!_isDetecting)
                  TextButton.icon(
                    onPressed: _detectGarment,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text("Detectar de nuevo"),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                hintText: "Ej. Camisa, Sudadera, Falda...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Color principal", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(
                hintText: "Ej. azul, rojo, blanco...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Temporadas (opcional)", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: temporadas.map((season) {
                final selected = _selectedSeasons.contains(season);
                return FilterChip(
                  label: Text(season),
                  selected: selected,
                  selectedColor: AppColors.pinkDark.withOpacity(0.2),
                  checkmarkColor: AppColors.pinkDark,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedSeasons.add(season);
                    } else {
                      _selectedSeasons.remove(season);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Guardar prenda"),
            ),
          ],
        ),
      ),
    );
  }
}