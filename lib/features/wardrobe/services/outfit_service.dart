import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/outfit_model.dart';

class OutfitService {
  final FirebaseFirestore _firestore;

  OutfitService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _outfitsRef =>
      _firestore.collection('outfits');

  Future<String> saveOutfit(OutfitModel outfit) async {
    final doc = await _outfitsRef.add(outfit.toMap());
    return doc.id;
  }

  Future<void> updateOutfit(String outfitId, Map<String, dynamic> data) async {
    await _outfitsRef.doc(outfitId).update(data);
  }

  Future<void> toggleFavorite(String outfitId, bool isFavorite) async {
    await _outfitsRef.doc(outfitId).update({'isFavorite': isFavorite});
  }

  Stream<List<OutfitModel>> watchUserOutfits(String userId) {
    return _outfitsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OutfitModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> deleteOutfit(String outfitId) async {
    await _outfitsRef.doc(outfitId).delete();
  }
}