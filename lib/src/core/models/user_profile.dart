class UserProfile {
  UserProfile({
    required this.fullName,
    required this.businessName,
    required this.whatsapp,
    required this.email,
    required this.photoPath,
    this.featureProduct = false,
    this.featureOutlets = false,
    this.featureBudget = false,
    this.onboardingComplete = false,
  });

  final String fullName;
  final String businessName;
  final String whatsapp;
  final String email;
  final String? photoPath;

  /// Per-feature toggles — synced to Supabase `profiles` table.
  final bool featureProduct;   // HPP Calculator & Product List
  final bool featureOutlets;   // Multi-outlet management
  final bool featureBudget;    // Budget & monthly targets
  final bool onboardingComplete;

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
    bool? featureProduct,
    bool? featureOutlets,
    bool? featureBudget,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      featureProduct: featureProduct ?? this.featureProduct,
      featureOutlets: featureOutlets ?? this.featureOutlets,
      featureBudget: featureBudget ?? this.featureBudget,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'businessName': businessName,
      'whatsapp': whatsapp,
      'email': email,
      'photoPath': photoPath,
      'featureProduct': featureProduct,
      'featureOutlets': featureOutlets,
      'featureBudget': featureBudget,
      'onboardingComplete': onboardingComplete,
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
      featureProduct: json['feature_product'] as bool? ??
          json['featureProduct'] as bool? ?? false,
      featureOutlets: json['feature_outlets'] as bool? ??
          json['featureOutlets'] as bool? ?? false,
      featureBudget: json['feature_budget'] as bool? ??
          json['featureBudget'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ??
          json['onboardingComplete'] as bool? ?? false,
    );
  }
}