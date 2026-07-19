import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/garment_model.dart';

class ChatMessage {
  final String role; // 'user' o 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toMap() => {'role': role, 'content': content};
}

class ChatService {
  static const String _baseUrl = 'https://armario-ia-backend.vercel.app';

  Future<String> sendMessage({
    required List<ChatMessage> history,
    required List<GarmentModel> garments,
    required String weather,
  }) async {
    final url = Uri.parse('$_baseUrl/api/chat');

    final body = jsonEncode({
      'messages': history.map((m) => m.toMap()).toList(),
      'garments': garments
          .map((g) => {
                'id': g.id,
                'type': g.type,
                'colorPrimary': g.colorPrimary,
                'seasons': g.seasons,
              })
          .toList(),
      'weather': weather,
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener respuesta (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data['error'] != null) {
      throw Exception('Error de la IA: ${data['error']}');
    }

    return data['reply'] ?? '';
  }
}