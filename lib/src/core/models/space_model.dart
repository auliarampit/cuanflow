enum SpaceType { personal, store, production }

extension SpaceTypeX on SpaceType {
  String get displayName => switch (this) {
        SpaceType.personal => 'Pribadi',
        SpaceType.store => 'Warung',
        SpaceType.production => 'Produksi',
      };

  static SpaceType fromString(String? v) => switch (v) {
        'store' => SpaceType.store,
        'production' => SpaceType.production,
        _ => SpaceType.personal,
      };
}

class SpaceModel {
  SpaceModel({
    required this.id,
    required this.type,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final SpaceType type;
  final DateTime createdAt;
  final bool isActive;

  SpaceModel copyWith({bool? isActive}) => SpaceModel(
        id: id,
        type: type,
        createdAt: createdAt,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory SpaceModel.fromJson(Map<String, dynamic> json) => SpaceModel(
        id: json['id'] as String,
        type: SpaceTypeX.fromString(json['type'] as String?),
        createdAt: DateTime.tryParse(
                json['createdAt'] as String? ??
                    json['created_at'] as String? ??
                    '') ??
            DateTime.now(),
        isActive: json['isActive'] as bool? ??
            json['is_active'] as bool? ??
            true,
      );
}
