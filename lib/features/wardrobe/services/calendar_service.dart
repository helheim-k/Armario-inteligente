import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/calendar_entry_model.dart';

class CalendarService {
  final FirebaseFirestore _firestore;

  CalendarService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _entriesRef =>
      _firestore.collection('calendar_entries');

  Stream<List<CalendarEntryModel>> watchEntriesInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _entriesRef
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CalendarEntryModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> saveEntry(CalendarEntryModel entry) async {
    final docId = _dateDocId(entry.userId, entry.date);
    await _entriesRef.doc(docId).set(entry.toMap());
  }

  Future<void> deleteEntry(String userId, DateTime date) async {
    final docId = _dateDocId(userId, date);
    await _entriesRef.doc(docId).delete();
  }

  String _dateDocId(String userId, DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${userId}_${normalized.toIso8601String().split('T').first}';
  }
}