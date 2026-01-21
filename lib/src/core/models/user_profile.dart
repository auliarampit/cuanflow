class UserProfile {
  UserProfile({
    required this.fullName,
    required this.businessName,
    required this.whatsapp,
    required this.email,
    required this.photoPath,
  });

  final String fullName;
  final String businessName;
  final String whatsapp;
  final String email;
  final String? photoPath;

  factory UserProfile.empty() {
    return UserProfile(
      fullName: '',
      businessName: '',
      whatsapp: '',
      email: '',
      photoPath: null,
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? businessName,
    String? whatsapp,
    String? email,
    String? photoPath,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'businessName': businessName,
      'whatsapp': whatsapp,
      'email': email,
      'photoPath': photoPath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
    );
  }
}