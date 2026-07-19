import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/garment_model.dart';

class OutfitPreviewSheet extends StatelessWidget {
  final List<GarmentModel> garments;
  final String? reason;

  const OutfitPreviewSheet({super.key, required this.garments, this.reason});

  static const List<String> _topTypes = ['Playera', 'Camisa', 'Blusa', 'Suéter', 'Top', 'Chaqueta', 'Abrigo'];
  static const List<String> _bottomTypes = ['Pantalón', 'Falda', 'Short', 'Bermuda', 'Pants'];
  static const List<String> _footwearTypes = ['Zapatos', 'Tenis', 'Botas', 'Sandalias'];

  List<GarmentModel> _filterByTypes(List<String> types) {
    return garments
        .where((g) => types.any((t) => g.type.toLowerCase().contains(t.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tops = _filterByTypes(_topTypes);
    final bottoms = _filterByTypes(_bottomTypes);
    final footwear = _filterByTypes(_footwearTypes);
    final usedIds = {...tops, ...bottoms, ...footwear}.map((g) => g.id).toSet();
    final others = garments.where((g) => !usedIds.contains(g.id)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "Vista previa del outfit",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (tops.isNotEmpty) _PreviewRow(garments: tops, label: "Parte superior"),
              if (bottoms.isNotEmpty) _PreviewRow(garments: bottoms, label: "Parte inferior"),
              if (footwear.isNotEmpty) _PreviewRow(garments: footwear, label: "Calzado"),
              if (others.isNotEmpty) _PreviewRow(garments: others, label: "Accesorios y otros"),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: AppColors.pinkDark),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reason!, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final List<GarmentModel> garments;
  final String label;

  const _PreviewRow({required this.garments, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: garments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(garments[i].imageBase64),
                  width: 110,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}