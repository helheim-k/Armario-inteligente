import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/wardrobe_controller.dart';
import '../models/garment_model.dart';
import 'garment_capture_screen.dart';

class GarmentListScreen extends StatefulWidget {
  const GarmentListScreen({super.key});

  @override
  State<GarmentListScreen> createState() => _GarmentListScreenState();
}

class _GarmentListScreenState extends State<GarmentListScreen> {
  final WardrobeController _wardrobeController = WardrobeController();
  late final Stream<List<GarmentModel>> _garmentsStream; // 👈 nuevo

  String _searchQuery = '';
  String? _selectedType;
  String? _selectedSeason;
  bool _onlyFavorites = false;

  static const List<String> _allSeasons = [
    'Primavera',
    'Verano',
    'Otoño',
    'Invierno',
  ];

  @override
  void initState() {
    super.initState();
    _garmentsStream = _wardrobeController.watchGarments(); // 👈 se crea UNA sola vez
  }

  List<GarmentModel> _applyFilters(List<GarmentModel> garments) {
    return garments.where((g) {
      final matchesQuery = _searchQuery.isEmpty ||
          g.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.colorPrimary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (g.pattern?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesType = _selectedType == null || g.type == _selectedType;
      final matchesSeason =
          _selectedSeason == null || g.seasons.contains(_selectedSeason);
      final matchesFavorite = !_onlyFavorites || g.isFavorite;

      return matchesQuery && matchesType && matchesSeason && matchesFavorite;
    }).toList();
  }

  Future<void> _confirmDelete(BuildContext context, GarmentModel garment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar prenda'),
        content: const Text('¿Seguro que quieres eliminar esta prenda?'),
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

    if (confirm == true && garment.id != null) {
      await _wardrobeController.deleteGarment(garment.id!);
    }
  }

  void _openEditSheet(GarmentModel garment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditGarmentSheet(
        garment: garment,
        allSeasons: _allSeasons,
        onSave: (updated) => _wardrobeController.updateGarment(updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mis prendas"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GarmentModel>>(
        stream: _garmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Ocurrió un error al cargar tus prendas: ${snapshot.error}"),
            );
          }

          final allGarments = snapshot.data ?? [];

          if (allGarments.isEmpty) {
            return const Center(
              child: Text("Todavía no has registrado ninguna prenda."),
            );
          }

          final types = allGarments.map((g) => g.type).toSet().toList()..sort();
          final filtered = _applyFilters(allGarments);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por tipo, color o patrón...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: const Text('❤️ Favoritos'),
                      selected: _onlyFavorites,
                      onSelected: (v) => setState(() => _onlyFavorites = v),
                    ),
                    const SizedBox(width: 8),
                    ...types.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (selected) => setState(
                              () => _selectedType = selected ? type : null,
                            ),
                          ),
                        )),
                    ...(_selectedType != null
                        ? [const SizedBox(width: 4)]
                        : []),
                    ..._allSeasons.map((season) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(season),
                            selected: _selectedSeason == season,
                            onSelected: (selected) => setState(
                              () => _selectedSeason = selected ? season : null,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text("No hay prendas que coincidan con tu búsqueda."),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final garment = filtered[index];
                          return _GarmentCard(
                            garment: garment,
                            onDelete: () => _confirmDelete(context, garment),
                            onEdit: () => _openEditSheet(garment),
                            onToggleFavorite: () =>
                                _wardrobeController.toggleFavorite(garment),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.pinkDark,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GarmentCaptureScreen()),
          );
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  final GarmentModel garment;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleFavorite;

  const _GarmentCard({
    required this.garment,
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
                  Image.memory(
                    base64Decode(garment.imageBase64),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          garment.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: garment.isFavorite ? Colors.redAccent : Colors.white,
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
                    garment.type,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    garment.colorPrimary,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (garment.seasons.isNotEmpty)
                    Text(
                      garment.seasons.join(', '),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
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

class _EditGarmentSheet extends StatefulWidget {
  final GarmentModel garment;
  final List<String> allSeasons;
  final Future<void> Function(GarmentModel) onSave;

  const _EditGarmentSheet({
    required this.garment,
    required this.allSeasons,
    required this.onSave,
  });

  @override
  State<_EditGarmentSheet> createState() => _EditGarmentSheetState();
}

class _EditGarmentSheetState extends State<_EditGarmentSheet> {
  late TextEditingController _typeController;
  late TextEditingController _colorController;
  late Set<String> _selectedSeasons;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.garment.type);
    _colorController = TextEditingController(text: widget.garment.colorPrimary);
    _selectedSeasons = widget.garment.seasons.toSet();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.garment.copyWith(
      type: _typeController.text.trim(),
      colorPrimary: _colorController.text.trim(),
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
          const Text('Editar prenda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _typeController,
            decoration: const InputDecoration(labelText: 'Tipo (ej. Camisa, Pantalón)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _colorController,
            decoration: const InputDecoration(labelText: 'Color principal'),
          ),
          const SizedBox(height: 12),
          const Text('Temporadas', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.allSeasons.map((season) {
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
          const SizedBox(height: 20),
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