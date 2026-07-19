import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';
import '../../wardrobe/models/garment_model.dart';
import '../../wardrobe/controllers/outfit_controller.dart';

class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  final WardrobeController _wardrobeController = WardrobeController();
  final OutfitController _outfitController = OutfitController();

  final _nameController = TextEditingController();
  final Set<String> _selectedGarmentIds = {};
  String? _selectedOccasion;
  final Set<String> _selectedSeasons = {};
  bool _saving = false;

  static const List<String> _occasions = [
    'Casual',
    'Formal',
    'Deportivo',
    'Trabajo',
  ];

  static const List<String> _allSeasons = [
    'Primavera',
    'Verano',
    'Otoño',
    'Invierno',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleGarment(String id) {
    setState(() {
      if (_selectedGarmentIds.contains(id)) {
        _selectedGarmentIds.remove(id);
      } else {
        _selectedGarmentIds.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_selectedGarmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una prenda para tu outfit.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _outfitController.createOutfit(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        garmentIds: _selectedGarmentIds.toList(),
        occasion: _selectedOccasion,
        seasons: _selectedSeasons.toList(),
        source: 'manual',
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo guardar el outfit. Intenta de nuevo.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Armar outfit"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GarmentModel>>(
        stream: _wardrobeController.watchGarments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final garments = snapshot.data ?? [];

          if (garments.isEmpty) {
            return const Center(
              child: Text("Registra prendas primero para poder armar un outfit."),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nombre del outfit (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ocasión", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _occasions.map((occasion) {
                        final selected = _selectedOccasion == occasion;
                        return ChoiceChip(
                          label: Text(occasion),
                          selected: selected,
                          onSelected: (v) => setState(
                            () => _selectedOccasion = v ? occasion : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text("Temporadas", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _allSeasons.map((season) {
                        final selected = _selectedSeasons.contains(season);
                        return FilterChip(
                          label: Text(season),
                          selected: selected,
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Elige las prendas (${_selectedGarmentIds.length} seleccionadas)",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: garments.length,
                  itemBuilder: (context, index) {
                    final garment = garments[index];
                    final selected = _selectedGarmentIds.contains(garment.id);
                    return GestureDetector(
                      onTap: () => _toggleGarment(garment.id!),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected ? AppColors.pinkDark : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.memory(
                                base64Decode(garment.imageBase64),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.pinkDark,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pinkDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Guardar outfit"),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}