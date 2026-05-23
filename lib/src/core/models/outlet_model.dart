class OutletModel {
  OutletModel({
    required this.id,
    required this.name,
    this.address,
    this.isDefault = false,
    this.spaceId,
  });

  final String id;
  final String name;
  final String? address;
  final bool isDefault;
  final String? spaceId;

  OutletModel copyWith({
    String? id,
    String? name,
    String? address,
    bool? isDefault,
    String? spaceId,
  }) {
    return OutletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
      spaceId: spaceId ?? this.spaceId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'is_default': isDefault,
      if (spaceId != null) 'space_id': spaceId,
    };
  }

  static OutletModel fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      spaceId: json['space_id'] as String?,
    );
  }
}
