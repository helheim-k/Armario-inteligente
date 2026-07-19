class CalendarEntryModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String? outfitId;
  final List<String> garmentIds;
  final String? note;
  final DateTime? createdAt;

  CalendarEntryModel({
    this.id,
    required this.userId,
    required this.date,
    this.outfitId,
    this.garmentIds = const [],
    this.note,
    this.createdAt,
  });

  factory CalendarEntryModel.fromMap(String id, Map<String, dynamic> map) {
    return CalendarEntryModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      outfitId: map['outfitId'],
      garmentIds: List<String>.from(map['garmentIds'] ?? const []),
      note: map['note'],
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'outfitId': outfitId,
      'garmentIds': garmentIds,
      'note': note,
      'createdAt': createdAt,
    };
  }
}