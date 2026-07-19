import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';
import '../../wardrobe/controllers/outfit_controller.dart';
import '../../wardrobe/models/garment_model.dart';
import '../../wardrobe/models/outfit_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Favoritos"),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.pinkDark,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.pinkDark,
            tabs: const [
              Tab(text: "Prendas"),
              Tab(text: "Outfits"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoriteGarmentsTab(),
            _FavoriteOutfitsTab(),
          ],
        ),
      ),
    );
  }
}

class _FavoriteGarmentsTab extends StatefulWidget {
  const _FavoriteGarmentsTab();

  @override
  State<_FavoriteGarmentsTab> createState() => _FavoriteGarmentsTabState();
}

class _FavoriteGarmentsTabState extends State<_FavoriteGarmentsTab> {
  final WardrobeController _wardrobeController = WardrobeController();
  late final Stream<List<GarmentModel>> _garmentsStream;

  @override
  void initState() {
    super.initState();
    _garmentsStream = _wardrobeController.watchGarments();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GarmentModel>>(
      stream: _garmentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = (snapshot.data ?? [])
            .where((g) => g.isFavorite)
            .toList();

        if (favorites.isEmpty) {
          return const Center(
            child: Text("Todavía no tienes prendas favoritas."),
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
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final garment = favorites[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          right: 4,
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                              onPressed: () => _wardrobeController.toggleFavorite(garment),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      garment.type,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FavoriteOutfitsTab extends StatefulWidget {
  const _FavoriteOutfitsTab();

  @override
  State<_FavoriteOutfitsTab> createState() => _FavoriteOutfitsTabState();
}

class _FavoriteOutfitsTabState extends State<_FavoriteOutfitsTab> {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GarmentModel>>(
      stream: _garmentsStream,
      builder: (context, garmentsSnapshot) {
        final allGarments = garmentsSnapshot.data ?? [];
        final garmentsById = {for (final g in allGarments) g.id: g};

        return StreamBuilder<List<OutfitModel>>(
          stream: _outfitsStream,
          builder: (context, outfitsSnapshot) {
            if (outfitsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final favorites = (outfitsSnapshot.data ?? [])
                .where((o) => o.isFavorite)
                .toList();

            if (favorites.isEmpty) {
              return const Center(
                child: Text("Todavía no tienes outfits favoritos."),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final outfit = favorites[index];
                final garments = outfit.garmentIds
                    .map((id) => garmentsById[id])
                    .whereType<GarmentModel>()
                    .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                outfit.name ?? 'Outfit sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.redAccent),
                              onPressed: () => _outfitController.toggleFavorite(outfit),
                            ),
                          ],
                        ),
                        if (outfit.occasion != null)
                          Text(
                            outfit.occasion!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: garments.isEmpty
                              ? const Text("Prendas no disponibles")
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: garments.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(garments[i].imageBase64),
                                        width: 70,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}