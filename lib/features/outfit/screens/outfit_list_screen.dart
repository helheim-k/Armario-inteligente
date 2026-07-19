import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';
import '../../wardrobe/controllers/outfit_controller.dart';
import '../../wardrobe/models/garment_model.dart';
import '../../wardrobe/models/outfit_model.dart';
import 'create_outfit_screen.dart';

class OutfitListScreen extends StatefulWidget {
  const OutfitListScreen({super.key});

  @override
  State<OutfitListScreen> createState() => _OutfitListScreenState();
}

class _OutfitListScreenState extends State<OutfitListScreen> {
  final WardrobeController _wardrobeController = WardrobeController();
  final OutfitController _outfitController = OutfitController();

  late final Stream<List<GarmentModel>> _garmentsStream;
  late final Stream<List<OutfitModel>> _outfitsStream;

  @override
  void initState() {
    super.initState();
    _garmentsStream = _wardrobeController.watchGarments();
    _outfitsStream = _outfitController.watchOutfits();
  }

  Future<void> _confirmDelete(BuildContext context, OutfitModel outfit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar outfit'),
        content: const Text('¿Seguro que quieres eliminar este outfit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && outfit.id != null) {
      await _outfitController.deleteOutfit(outfit.id!);
    }
  }

  void _openEditSheet(OutfitModel outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditOutfitSheet(
        outfit: outfit,
        onSave: (updated) => _outfitController.updateOutfit(updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Outfits"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GarmentModel>>(
        stream: _garmentsStream,
        builder: (context, garmentsSnapshot) {
          final garmentsById = {
            for (final g in garmentsSnapshot.data ?? <GarmentModel>[]) g.id: g,
          };

          return StreamBuilder<List<OutfitModel>>(
            stream: _outfitsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("Ocurrió un error al cargar tus outfits: ${snapshot.error}"),
                );
              }

              final outfits = snapshot.data ?? [];

              if (outfits.isEmpty) {
                return const Center(
                  child: Text("Todavía no has armado ningún outfit."),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  final outfit = outfits[index];
                  final garments = outfit.garmentIds
                      .map((id) => garmentsById[id])
                      .whereType<GarmentModel>()
                      .toList();

                  return _OutfitCard(
                    outfit: outfit,
                    garments: garments,
                    onDelete: () => _confirmDelete(context, outfit),
                    onEdit: () => _openEditSheet(outfit),
                    onToggleFavorite: () => _outfitController.toggleFavorite(outfit),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.pinkDark,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOutfitScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final List<GarmentModel> garments;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleFavorite;

  const _OutfitCard({
    required this.outfit,
    required this.garments,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _OutfitCollage(garments: garments),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          outfit.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: outfit.isFavorite ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                        onPressed: onDelete,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name ?? 'Outfit sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (outfit.occasion != null)
                    Text(
                      outfit.occasion!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collage simple: 1 prenda = foto completa, 2-4 prendas = cuadrícula 2x2.
class _OutfitCollage extends StatelessWidget {
  final List<GarmentModel> garments;

  const _OutfitCollage({required this.garments});

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.checkroom, size: 40, color: Colors.grey),
      );
    }

    if (garments.length == 1) {
      return Image.memory(base64Decode(garments[0].imageBase64), fit: BoxFit.cover);
    }

    final shown = garments.take(4).toList();
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: shown
          .map((g) => Image.memory(base64Decode(g.imageBase64), fit: BoxFit.cover))
          .toList(),
    );
  }
}

class _EditOutfitSheet extends StatefulWidget {
  final OutfitModel outfit;
  final Future<void> Function(OutfitModel) onSave;

  const _EditOutfitSheet({required this.outfit, required this.onSave});

  @override
  State<_EditOutfitSheet> createState() => _EditOutfitSheetState();
}

class _EditOutfitSheetState extends State<_EditOutfitSheet> {
  late TextEditingController _nameController;
  String? _selectedOccasion;
  late Set<String> _selectedSeasons;
  bool _saving = false;

  static const List<String> _occasions = ['Casual', 'Formal', 'Deportivo', 'Trabajo'];
  static const List<String> _allSeasons = ['Primavera', 'Verano', 'Otoño', 'Invierno'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outfit.name ?? '');
    _selectedOccasion = widget.outfit.occasion;
    _selectedSeasons = widget.outfit.seasons.toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.outfit.copyWith(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      occasion: _selectedOccasion,
      seasons: _selectedSeasons.toList(),
    );
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Editar outfit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre del outfit'),
          ),
          const SizedBox(height: 16),
          const Text('Ocasión', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _occasions.map((occasion) {
              final selected = _selectedOccasion == occasion;
              return ChoiceChip(
                label: Text(occasion),
                selected: selected,
                onSelected: (v) => setState(() => _selectedOccasion = v ? occasion : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Temporadas', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}