class GarmentModel {
  final String? id;
  final String userId;
  final String imageBase64;
  final String type;
  final String colorPrimary;
  final String? colorSecondary;
  final String? pattern;
  final String? formality;
  final List<String> seasons; // ej: ['Primavera', 'Verano']
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GarmentModel({
    this.id,
    required this.userId,
    required this.imageBase64,
    required this.type,
    required this.colorPrimary,
    this.colorSecondary,
    this.pattern,
    this.formality,
    this.seasons = const [],
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  factory GarmentModel.fromMap(String id, Map<String, dynamic> map) {
    return GarmentModel(
      id: id,
      userId: map['userId'] ?? '',
      imageBase64: map['imageBase64'] ?? '',
      type: map['type'] ?? '',
      colorPrimary: map['colorPrimary'] ?? '',
      colorSecondary: map['colorSecondary'],
      pattern: map['pattern'],
      formality: map['formality'],
      seasons: List<String>.from(map['seasons'] ?? const []),
      isFavorite: map['isFavorite'] ?? false,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageBase64': imageBase64,
      'type': type,
      'colorPrimary': colorPrimary,
      'colorSecondary': colorSecondary,
      'pattern': pattern,
      'formality': formality,
      'seasons': seasons,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  GarmentModel copyWith({
    String? type,
    String? colorPrimary,
    String? colorSecondary,
    String? pattern,
    String? formality,
    List<String>? seasons,
    bool? isFavorite,
  }) {
    return GarmentModel(
      id: id,
      userId: userId,
      imageBase64: imageBase64,
      type: type ?? this.type,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      pattern: pattern ?? this.pattern,
      formality: formality ?? this.formality,
      seasons: seasons ?? this.seasons,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}