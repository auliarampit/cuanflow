import '../config/feature_config.dart';
import 'subscription_tier.dart';

class UserProfile implements HasFeatures {
  UserProfile({
    required this.fullName,
    required this.businessName,
    required this.whatsapp,
    required this.email,
    required this.photoPath,
    this.featureProduct = false,
    this.featureOutlets = false,
    this.featureBudget = false,
    this.featureProduction = false,
    this.featureQuickSale = false,
    this.featureTopCategories = false,
    this.featureBusiestDay = false,
    this.featureStock = false,
    this.featureProductAnalytics = false,
    this.featureDebt = false,
    this.featureRecurring = true,
    this.onboardingComplete = false,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.isBusinessPremium = false,
    this.businessPremiumUntil,
  });

  final String fullName;
  final String businessName;
  final String whatsapp;
  final String email;
  final String? photoPath;

  /// Per-feature toggles — synced to Supabase `profiles` table.
  final bool featureProduct;        // HPP Calculator & Product List
  final bool featureOutlets;       // Multi-outlet management
  final bool featureBudget;        // Budget & monthly targets
  final bool featureProduction;    // Bahan Baku & Batch Produksi
  final bool featureQuickSale;      // Jual Cepat (Quick Sale)
  final bool featureTopCategories; // Insight: Kategori Terlaris
  final bool featureBusiestDay;    // Insight: Hari Tersibuk
  final bool featureStock;
  final bool featureProductAnalytics;
  final bool featureDebt;
  final bool featureRecurring;
  final bool onboardingComplete;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final bool isBusinessPremium;
  final DateTime? businessPremiumUntil;

  // ============================================================================
  // HasFeatures Implementation - useFeature() Pattern
  // ============================================================================

  @override
  bool hasFeature(Feature feature) {
    switch (feature) {
      case Feature.product:
        return featureProduct;
      case Feature.outlets:
        return featureOutlets;
      case Feature.budget:
        return featureBudget;
      case Feature.production:
        return featureProduction;
      case Feature.quickSale:
        return featureQuickSale;
      case Feature.topCategories:
        return featureTopCategories;
      case Feature.busiestDay:
        return featureBusiestDay;
      case Feature.stock:
        return featureStock;
      case Feature.productAnalytics:
        return featureProductAnalytics;
      case Feature.debt:
        return featureDebt;
      case Feature.recurring:
        return featureRecurring;
    }
  }

  /// Legacy: isBusinessMode computed from features
  bool get isBusinessMode =>
      featureOutlets ||
      featureBudget ||
      featureProduct ||
      featureProduction ||
      featureQuickSale ||
      featureStock ||
      featureProductAnalytics ||
      featureDebt;

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
    bool? featureProduction,
    bool? featureQuickSale,
    bool? featureTopCategories,
    bool? featureBusiestDay,
    // NEW
    bool? featureStock,
    bool? featureProductAnalytics,
    bool? featureDebt,
    bool? featureRecurring,
    bool? onboardingComplete,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    bool clearSubscriptionExpiry = false,
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
      featureProduct: featureProduct ?? this.featureProduct,
      featureOutlets: featureOutlets ?? this.featureOutlets,
      featureBudget: featureBudget ?? this.featureBudget,
      featureProduction: featureProduction ?? this.featureProduction,
      featureQuickSale: featureQuickSale ?? this.featureQuickSale,
      featureTopCategories: featureTopCategories ?? this.featureTopCategories,
      featureBusiestDay: featureBusiestDay ?? this.featureBusiestDay,
      featureStock: featureStock ?? this.featureStock,
      featureProductAnalytics: featureProductAnalytics ?? this.featureProductAnalytics,
      featureDebt: featureDebt ?? this.featureDebt,
      featureRecurring: featureRecurring ?? this.featureRecurring,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: clearSubscriptionExpiry ? null : (subscriptionExpiry ?? this.subscriptionExpiry),
      isBusinessPremium: isBusinessPremium ?? this.isBusinessPremium,
      businessPremiumUntil: clearBusinessPremiumUntil ? null : (businessPremiumUntil ?? this.businessPremiumUntil),
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
      'featureProduction': featureProduction,
      'featureQuickSale': featureQuickSale,
      'featureTopCategories': featureTopCategories,
      'featureBusiestDay': featureBusiestDay,
      'featureStock': featureStock,
      'featureProductAnalytics': featureProductAnalytics,
      'featureDebt': featureDebt,
      'featureRecurring': featureRecurring,
      'onboardingComplete': onboardingComplete,
      'subscriptionTier': subscriptionTier.value,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
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
      featureProduct: json['feature_product'] as bool? ??
          json['featureProduct'] as bool? ?? false,
      featureOutlets: json['feature_outlets'] as bool? ??
          json['featureOutlets'] as bool? ?? false,
      featureBudget: json['feature_budget'] as bool? ??
          json['featureBudget'] as bool? ?? false,
      featureProduction: json['feature_production'] as bool? ??
          json['featureProduction'] as bool? ?? false,
      featureQuickSale: json['feature_quick_sale'] as bool? ??
          json['featureQuickSale'] as bool? ?? false,
      featureTopCategories: json['feature_top_categories'] as bool? ??
          json['featureTopCategories'] as bool? ?? false,
      featureBusiestDay: json['feature_busiest_day'] as bool? ??
          json['featureBusiestDay'] as bool? ?? false,
      featureStock: json['feature_stock'] as bool? ??
          json['featureStock'] as bool? ?? false,
      featureProductAnalytics: json['feature_product_analytics'] as bool? ??
          json['featureProductAnalytics'] as bool? ?? false,
      featureDebt: json['feature_debt'] as bool? ??
          json['featureDebt'] as bool? ?? false,
      featureRecurring: json['feature_recurring'] as bool? ??
          json['featureRecurring'] as bool? ?? true,
      onboardingComplete: json['onboarding_complete'] as bool? ??
          json['onboardingComplete'] as bool? ?? false,
      subscriptionTier: SubscriptionTier.fromString(
        json['subscription_tier'] as String? ??
            json['subscriptionTier'] as String?,
      ),
      subscriptionExpiry: json['subscriptionExpiry'] != null
          ? DateTime.tryParse(json['subscriptionExpiry'] as String)
          : null,
      isBusinessPremium: json['is_business_premium'] as bool? ??
          json['isBusinessPremium'] as bool? ?? false,
      businessPremiumUntil: json['business_premium_until'] != null
          ? DateTime.tryParse(json['business_premium_until'] as String)
          : json['businessPremiumUntil'] != null
              ? DateTime.tryParse(json['businessPremiumUntil'] as String)
              : null,
    );
  }
}
