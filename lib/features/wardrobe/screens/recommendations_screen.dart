import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/wardrobe_controller.dart';
import '../controllers/outfit_controller.dart';
import '../models/garment_model.dart';
import '../services/recommendation_service.dart';
import '../../home/services/weather_service.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final WardrobeController _wardrobeController = WardrobeController();
  final OutfitController _outfitController = OutfitController();
  final RecommendationService _recommendationService = RecommendationService();
  final WeatherService _weatherService = WeatherService();

  late final Stream<List<GarmentModel>> _garmentsStream;

  String? _selectedOccasion;
  bool _loading = false;
  String? _error;
  List<RecommendedOutfit> _recommendations = [];
  final Set<int> _savingIndexes = {};

  static const List<String> _occasions = ['Casual', 'Formal', 'Deportivo', 'Trabajo'];

  @override
  void initState() {
    super.initState();
    _garmentsStream = _wardrobeController.watchGarments();
  }

  Future<void> _generate(List<GarmentModel> garments) async {
    if (garments.isEmpty) {
      setState(() => _error = 'Registra prendas primero para poder generar recomendaciones.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _recommendations = [];
    });

    try {
      String weatherDescription = 'no especificado';
      try {
        final weather = await _weatherService.getCurrentWeather();
        weatherDescription = '${weather.description}, ${weather.temperature.round()}°C';
      } catch (_) {
        // Si el clima falla, seguimos sin él, no bloqueamos la recomendación.
      }

      final results = await _recommendationService.generateOutfits(
        garments: garments,
        weather: weatherDescription,
        occasion: _selectedOccasion ?? 'casual',
      );

      setState(() => _recommendations = results);
    } catch (e) {
      setState(() => _error = 'No se pudieron generar recomendaciones. Intenta de nuevo.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRecommendation(int index, RecommendedOutfit rec) async {
    setState(() => _savingIndexes.add(index));
    try {
      await _outfitController.createOutfit(
        garmentIds: rec.garmentIds,
        occasion: _selectedOccasion,
        source: 'ia',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit guardado en tu lista de Outfits.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el outfit.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingIndexes.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Recomendaciones IA"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GarmentModel>>(
        stream: _garmentsStream,
        builder: (context, snapshot) {
          final garments = snapshot.data ?? [];
          final garmentsById = {for (final g in garments) g.id: g};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ocasión", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _generate(garments),
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_loading ? "Generando..." : "Generar recomendaciones"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pinkDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_recommendations.isNotEmpty)
                  ..._recommendations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final rec = entry.value;
                    final recGarments = rec.garmentIds
                        .map((id) => garmentsById[id])
                        .whereType<GarmentModel>()
                        .toList();
                    final isSaving = _savingIndexes.contains(index);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Opción ${index + 1}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: recGarments.isEmpty
                                  ? const Text("Prendas no disponibles")
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recGarments.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (context, i) => ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                          base64Decode(recGarments[i].imageBase64),
                                          width: 80,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(rec.reason, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: isSaving ? null : () => _saveRecommendation(index, rec),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text("Guardar como outfit"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}