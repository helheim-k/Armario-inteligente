import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherInfo {
  final double temperature;
  final String description;
  final String iconCode; // código de OpenWeatherMap, ej. "01d"

  WeatherInfo({
    required this.temperature,
    required this.description,
    required this.iconCode,
  });
}

class WeatherService {
  // ⚠️ Reemplaza esto con tu API key de OpenWeatherMap
  static const String _apiKey = '84448692502088369b94e7e2bf318f6e';

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado en el dispositivo.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Si no llega un fix nuevo a tiempo, intenta usar la última ubicación conocida.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw Exception('No se pudo obtener tu ubicación (tiempo agotado).');
    }
  }

  Future<WeatherInfo> getCurrentWeather() async {
    final position = await _getCurrentPosition();

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${position.latitude}&lon=${position.longitude}'
      '&appid=$_apiKey&units=metric&lang=es',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener el clima (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    return WeatherInfo(
      temperature: (data['main']['temp'] as num).toDouble(),
      description: data['weather'][0]['description'] ?? '',
      iconCode: data['weather'][0]['icon'] ?? '01d',
    );
  }
}