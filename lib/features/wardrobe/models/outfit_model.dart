class OutfitModel {
  final String? id;
  final String userId;
  final String? name;
  final List<String> garmentIds;
  final String? occasion; // ej. Casual, Formal, Deportivo, Trabajo
  final List<String> seasons;
  final bool isFavorite;
  final String source; // 'manual' o 'ia'
  final DateTime? createdAt;

  OutfitModel({
    this.id,
    required this.userId,
    this.name,
    required this.garmentIds,
    this.occasion,
    this.seasons = const [],
    this.isFavorite = false,
    this.source = 'manual',
    this.createdAt,
  });

  factory OutfitModel.fromMap(String id, Map<String, dynamic> map) {
    return OutfitModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'],
      garmentIds: List<String>.from(map['garmentIds'] ?? const []),
      occasion: map['occasion'],
      seasons: List<String>.from(map['seasons'] ?? const []),
      isFavorite: map['isFavorite'] ?? false,
      source: map['source'] ?? 'manual',
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'garmentIds': garmentIds,
      'occasion': occasion,
      'seasons': seasons,
      'isFavorite': isFavorite,
      'source': source,
      'createdAt': createdAt,
    };
  }

  OutfitModel copyWith({
    String? name,
    List<String>? garmentIds,
    String? occasion,
    List<String>? seasons,
    bool? isFavorite,
  }) {
    return OutfitModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      garmentIds: garmentIds ?? this.garmentIds,
      occasion: occasion ?? this.occasion,
      seasons: seasons ?? this.seasons,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source,
      createdAt: createdAt,
    );
  }
}
