import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/garment_model.dart';

class WardrobeService {
  final FirebaseFirestore _firestore;

  WardrobeService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _garmentsRef =>
      _firestore.collection('garments');

  Future<String> saveGarment(GarmentModel garment) async {
    final doc = await _garmentsRef.add(garment.toMap());
    return doc.id;
  }

  Future<void> updateGarment(String garmentId, Map<String, dynamic> data) async {
    await _garmentsRef.doc(garmentId).update(data);
  }

  Future<void> toggleFavorite(String garmentId, bool isFavorite) async {
    await _garmentsRef.doc(garmentId).update({'isFavorite': isFavorite});
  }

  Stream<List<GarmentModel>> watchUserGarments(String userId) {
    return _garmentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GarmentModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> deleteGarment(String garmentId) async {
    await _garmentsRef.doc(garmentId).delete();
  }
}