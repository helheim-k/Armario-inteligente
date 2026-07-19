import 'dart:convert';
import 'dart:typed_data';

import '../../auth/services/auth_service.dart';
import '../models/garment_model.dart';
import '../services/wardrobe_service.dart';

class WardrobeController {
  final WardrobeService _wardrobeService;
  final AuthService _authService;

  WardrobeController({
    WardrobeService? wardrobeService,
    AuthService? authService,
  })  : _wardrobeService = wardrobeService ?? WardrobeService(),
        _authService = authService ?? AuthService();

  Stream<List<GarmentModel>> watchGarments() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _wardrobeService.watchUserGarments(uid);
  }

  Future<void> registerGarment({
    required Uint8List imageBytes,
    required String type,
    required String colorPrimary,
    String? colorSecondary,
    String? pattern,
    String? formality,
    List<String> seasons = const [],
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    final imageBase64 = base64Encode(imageBytes);

    final garment = GarmentModel(
      userId: uid,
      imageBase64: imageBase64,
      type: type,
      colorPrimary: colorPrimary,
      colorSecondary: colorSecondary,
      pattern: pattern,
      formality: formality,
      seasons: seasons,
      createdAt: DateTime.now(),
    );

    await _wardrobeService.saveGarment(garment);
  }

  Future<void> updateGarment(GarmentModel updated) async {
    if (updated.id == null) return;
    await _wardrobeService.updateGarment(updated.id!, updated.toMap());
  }

  Future<void> toggleFavorite(GarmentModel garment) async {
    if (garment.id == null) return;
    await _wardrobeService.toggleFavorite(garment.id!, !garment.isFavorite);
  }

  Future<void> deleteGarment(String garmentId) {
    return _wardrobeService.deleteGarment(garmentId);
  }
}