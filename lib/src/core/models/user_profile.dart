class UserProfile {
  UserProfile({
    required this.fullName,
    required this.businessName,
    required this.whatsapp,
    required this.email,
    required this.photoPath,
    this.onboardingComplete = false,
    this.isBusinessPremium = false,
    this.businessPremiumUntil,
  });

  final String fullName;
  final String businessName;
  final String whatsapp;
  final String email;
  final String? photoPath;
  final bool onboardingComplete;
  final bool isBusinessPremium;
  final DateTime? businessPremiumUntil;

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
    bool? onboardingComplete,
    bool? isBusinessPremium,
    DateTime? businessPremiumUntil,
    bool clearBusinessPremiumUntil = false,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      isBusinessPremium: isBusinessPremium ?? this.isBusinessPremium,
      businessPremiumUntil: clearBusinessPremiumUntil
          ? null
          : (businessPremiumUntil ?? this.businessPremiumUntil),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'businessName': businessName,
      'whatsapp': whatsapp,
      'email': email,
      'photoPath': photoPath,
      'onboardingComplete': onboardingComplete,
      'isBusinessPremium': isBusinessPremium,
      'businessPremiumUntil': businessPremiumUntil?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['owner_name'] as String? ??
          json['full_name'] as String? ??
          json['fullName'] as String? ??
          '',
      businessName: json['business_name'] as String? ??
          json['businessName'] as String? ??
          '',
      whatsapp: json['whatsapp'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ??
          json['onboardingComplete'] as bool? ??
          false,
      isBusinessPremium: json['is_business_premium'] as bool? ??
          json['isBusinessPremium'] as bool? ??
          false,
      businessPremiumUntil: json['business_premium_until'] != null
          ? DateTime.tryParse(json['business_premium_until'] as String)
          : json['businessPremiumUntil'] != null
              ? DateTime.tryParse(json['businessPremiumUntil'] as String)
              : null,
    );
  }
}
