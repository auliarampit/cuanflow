class UserProfile {
  UserProfile({
    required this.fullName,
    required this.businessName,
    required this.whatsapp,
    required this.email,
    // required this.photoPath,
  });

  final String fullName;
  final String businessName;
  final String whatsapp;
  final String email;
  // final String? photoPath;

  factory UserProfile.empty() {
    return UserProfile(
      fullName: '',
      businessName: '',
      whatsapp: '',
      email: '',
      // photoPath: null,
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? businessName,
    String? whatsapp,
    String? email,
    // String? photoPath,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      // photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'business_name': businessName,
      'whatsapp': whatsapp,
      'email': email,
      // 'photo_path': photoPath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName:
          json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      businessName: json['business_name'] as String? ??
          json['businessName'] as String? ??
          '',
      whatsapp: json['whatsapp'] as String? ?? '',
      email: json['email'] as String? ?? '',
      // photoPath: json['photo_path'] as String? ?? json['photoPath'] as String?,
    );
  }
}