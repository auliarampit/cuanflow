class OutletModel {
  OutletModel({
    required this.id,
    required this.name,
    this.address,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String? address;
  final bool isDefault;

  OutletModel copyWith({
    String? id,
    String? name,
    String? address,
    bool? isDefault,
  }) {
    return OutletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'is_default': isDefault,
    };
  }

  static OutletModel fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
