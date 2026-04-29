import '../config/feature_config.dart';

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
    // NEW: 3 fitur tambahan
    this.featureStock = false,
    this.featureProductAnalytics = false,
    this.featureDebt = false,
    this.onboardingComplete = false,
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
  // NEW
  final bool featureStock;          // Stok Barang (Inventory)
  final bool featureProductAnalytics; // Analitik Produk
  final bool featureDebt;           // Utang & Piutang
  final bool onboardingComplete;

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
      // NEW: 3 fitur tambahan
      case Feature.stock:
        return featureStock;
      case Feature.productAnalytics:
        return featureProductAnalytics;
      case Feature.debt:
        return featureDebt;
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
      featureProduction: featureProduction ?? this.featureProduction,
      featureQuickSale: featureQuickSale ?? this.featureQuickSale,
      featureTopCategories: featureTopCategories ?? this.featureTopCategories,
      featureBusiestDay: featureBusiestDay ?? this.featureBusiestDay,
      // NEW
      featureStock: featureStock ?? this.featureStock,
      featureProductAnalytics: featureProductAnalytics ?? this.featureProductAnalytics,
      featureDebt: featureDebt ?? this.featureDebt,
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
      'featureProduction': featureProduction,
      'featureQuickSale': featureQuickSale,
      'featureTopCategories': featureTopCategories,
      'featureBusiestDay': featureBusiestDay,
      // NEW
      'featureStock': featureStock,
      'featureProductAnalytics': featureProductAnalytics,
      'featureDebt': featureDebt,
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
      featureProduction: json['feature_production'] as bool? ??
          json['featureProduction'] as bool? ?? false,
      featureQuickSale: json['feature_quick_sale'] as bool? ??
          json['featureQuickSale'] as bool? ?? false,
      featureTopCategories: json['feature_top_categories'] as bool? ??
          json['featureTopCategories'] as bool? ?? false,
      featureBusiestDay: json['feature_busiest_day'] as bool? ??
          json['featureBusiestDay'] as bool? ?? false,
      // NEW
      featureStock: json['feature_stock'] as bool? ??
          json['featureStock'] as bool? ?? false,
      featureProductAnalytics: json['feature_product_analytics'] as bool? ??
          json['featureProductAnalytics'] as bool? ?? false,
      featureDebt: json['feature_debt'] as bool? ??
          json['featureDebt'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ??
          json['onboardingComplete'] as bool? ?? false,
    );
  }
}
