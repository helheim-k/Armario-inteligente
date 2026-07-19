import '../../auth/services/auth_service.dart';
import '../models/outfit_model.dart';
import '../services/outfit_service.dart';

class OutfitController {
  final OutfitService _outfitService;
  final AuthService _authService;

  OutfitController({
    OutfitService? outfitService,
    AuthService? authService,
  })  : _outfitService = outfitService ?? OutfitService(),
        _authService = authService ?? AuthService();

  Stream<List<OutfitModel>> watchOutfits() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _outfitService.watchUserOutfits(uid);
  }

  Future<void> createOutfit({
    String? name,
    required List<String> garmentIds,
    String? occasion,
    List<String> seasons = const [],
    String source = 'manual',
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    if (garmentIds.isEmpty) {
      throw Exception('Un outfit necesita al menos una prenda');
    }

    final outfit = OutfitModel(
      userId: uid,
      name: name,
      garmentIds: garmentIds,
      occasion: occasion,
      seasons: seasons,
      source: source,
      createdAt: DateTime.now(),
    );

    await _outfitService.saveOutfit(outfit);
  }

  Future<void> updateOutfit(OutfitModel updated) async {
    if (updated.id == null) return;
    await _outfitService.updateOutfit(updated.id!, updated.toMap());
  }

  Future<void> toggleFavorite(OutfitModel outfit) async {
    if (outfit.id == null) return;
    await _outfitService.toggleFavorite(outfit.id!, !outfit.isFavorite);
  }

  Future<void> deleteOutfit(String outfitId) {
    return _outfitService.deleteOutfit(outfitId);
  }
}