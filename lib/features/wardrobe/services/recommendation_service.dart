import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/garment_model.dart';

class RecommendedOutfit {
  final List<String> garmentIds;
  final String reason;

  RecommendedOutfit({required this.garmentIds, required this.reason});

  factory RecommendedOutfit.fromMap(Map<String, dynamic> map) {
    return RecommendedOutfit(
      garmentIds: List<String>.from(map['garmentIds'] ?? []),
      reason: map['reason'] ?? '',
    );
  }
}

class RecommendationService {
  // ⚠️ Reemplaza con tu URL real de Vercel si es distinta
  static const String _baseUrl = 'https://armario-ia-backend.vercel.app';

  Future<List<RecommendedOutfit>> generateOutfits({
    required List<GarmentModel> garments,
    required String weather,
    required String occasion,
  }) async {
    final url = Uri.parse('$_baseUrl/api/generate-outfits');

    final body = jsonEncode({
      'garments': garments
          .map((g) => {
                'id': g.id,
                'type': g.type,
                'colorPrimary': g.colorPrimary,
                'seasons': g.seasons,
              })
          .toList(),
      'weather': weather,
      'occasion': occasion,
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('No se pudieron generar recomendaciones (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    if (data['error'] != null) {
      throw Exception('Error de la IA: ${data['error']}');
    }

    final outfitsRaw = data['outfits'] as List<dynamic>? ?? [];
    return outfitsRaw.map((o) => RecommendedOutfit.fromMap(o)).toList();
  }
}