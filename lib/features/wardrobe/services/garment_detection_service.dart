import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class DetectedGarment {
  final String? type;
  final String? colorPrimary;
  final String? colorSecondary;
  final String? pattern;
  final String? formality;

  DetectedGarment({
    this.type,
    this.colorPrimary,
    this.colorSecondary,
    this.pattern,
    this.formality,
  });

  factory DetectedGarment.fromMap(Map<String, dynamic> map) {
    return DetectedGarment(
      type: map['type'],
      colorPrimary: map['colorPrimary'],
      colorSecondary: map['colorSecondary'],
      pattern: map['pattern'],
      formality: map['formality'],
    );
  }
}

class GarmentDetectionService {
  // ⚠️ Usa la misma URL de tu backend en Vercel
  static const String _baseUrl = 'https://armario-ia-backend.vercel.app';

  Future<DetectedGarment> detectGarment(Uint8List imageBytes) async {
    final url = Uri.parse('$_baseUrl/api/detect-garment');
    final imageBase64 = base64Encode(imageBytes);

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'imageBase64': imageBase64}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('No se pudo detectar la prenda (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    if (data['error'] != null) {
      throw Exception('Error de la IA: ${data['error']}');
    }

    return DetectedGarment.fromMap(data);
  }
}