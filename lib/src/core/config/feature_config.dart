/// Feature Configuration - Single Source of Truth
/// 
/// Three business modes:
/// - personal: Minimal features for individual use
/// - store: Business features (quick sale, top products, etc.)
/// - production: Full features (HPP, inventory, production batch)
/// 
/// Usage:
/// ```dart
/// import 'package:cari_untung/src/core/config/feature_config.dart';
/// 
/// // Check specific feature
/// final canUseFastSale = useFeature(Feature.quickSale, profile);
/// 
/// // Or use the extension
/// final hasFastSale = profile.hasFeature(Feature.quickSale);
/// ```

// ============================================================================
// Enums
// ============================================================================

/// Business mode enum - matches featureConfig.ts BusinessMode
enum BusinessMode {
  personal('personal'),
  store('store'),
  production('production');

  const BusinessMode(this.value);
  final String value;
  
  static BusinessMode fromString(String value) {
    return BusinessMode.values.firstWhere(
      (m) => m.value == value,
      orElse: () => BusinessMode.personal,
    );
  }
}

/// Feature flag enum - matches featureConfig.ts FeatureFlags
enum Feature {
  // Existing features
  product('featureProduct', 'HPP Calculator & Product List'),
  outlets('featureOutlets', 'Multi-outlet management'),
  budget('featureBudget', 'Budget & monthly targets'),
  production('featureProduction', 'Bahan Baku & Batch Produksi'),
  quickSale('featureQuickSale', 'Jual Cepat (Quick Sale)'),
  topCategories('featureTopCategories', 'Insight: Kategori Terlaris'),
  busiestDay('featureBusiestDay', 'Insight: Hari Tersibuk'),
  
  // NEW: Stok barang (store) - inventory stock management
  stock('featureStock', 'Stok Barang (Inventory)'),
  
  // NEW: Analitik produk (store dan production) - product analytics
  productAnalytics('featureProductAnalytics', 'Analitik Produk'),
  
  // NEW: Utang & piutang (belum ada toggle di menu) - debt & receivable
  debt('featureDebt', 'Utang & Piutang');

  const Feature(this.key, this.description);
  final String key;
  final String description;
}

// ============================================================================
// Feature Config - Single Source of Truth
// ============================================================================

/// Feature configuration per mode - matches featureConfig.ts
const Map<BusinessMode, Map<Feature, bool>> featureConfig = {
  BusinessMode.personal: {
    Feature.product: false,
    Feature.outlets: false,
    Feature.budget: false,
    Feature.production: false,
    Feature.quickSale: false,
    Feature.topCategories: false,
    Feature.busiestDay: false,
    Feature.stock: false,           // ❌ Stok barang
    Feature.productAnalytics: false, // ❌ Analitik produk
    Feature.debt: false,            // ❌ Utang & piutang
  },
  BusinessMode.store: {
    Feature.product: false,
    Feature.outlets: false,
    Feature.budget: false,
    Feature.production: false,
    Feature.quickSale: true,        // ✅ Fast Sale
    Feature.topCategories: true,   // ✅ Top Products
    Feature.busiestDay: true,
    Feature.stock: true,            // ✅ Stok barang (store)
    Feature.productAnalytics: true, // ✅ Analitik produk (store)
    Feature.debt: false,           // ❌ Utang & piutang
  },
  BusinessMode.production: {
    Feature.product: true,         // ✅ HPP Calculator
    Feature.outlets: true,
    Feature.budget: true,
    Feature.production: true,     // ✅ Inventory & Batch Produksi
    Feature.quickSale: false,      // ❌ Fast Sale (production mode fokus ke HPP)
    Feature.topCategories: false, // ❌ Top Products (production fokus ke HPP)
    Feature.busiestDay: false,
    Feature.stock: true,          // ✅ Stok barang (production)
    Feature.productAnalytics: true, // ✅ Analitik produk (production)
    Feature.debt: true,           // ✅ Utang & piutang (production)
  },
};

// ============================================================================
// Core Functions - useFeature() Pattern
// ============================================================================

/// Core function: Check if a feature is enabled
/// Replaces hardcoded conditions like: mode == 'personal' || profile.isBusinessMode
/// 
/// Example:
/// ```dart
/// // Before:
/// if (profile.isBusinessMode) { ... }
/// 
/// // After:
/// if (useFeature(Feature.quickSale, profile)) { ... }
/// ```
bool useFeature(Feature feature, dynamic profile) {
  // Support UserProfile object
  if (profile is HasFeatures) {
    return profile.hasFeature(feature);
  }
  
  // Support BusinessMode enum
  if (profile is BusinessMode) {
    return featureConfig[profile]?[feature] ?? false;
  }
  
  // Support legacy bool (isBusinessMode)
  if (profile is bool) {
    return profile && (_featureDefaults[feature] ?? false);
  }
  
  return false;
}

/// Check multiple features at once
Map<Feature, bool> useFeatures(List<Feature> features, dynamic profile) {
  return {
    for (final feature in features) feature: useFeature(feature, profile),
  };
}

/// Get all features for a mode
Map<Feature, bool> getFeaturesForMode(BusinessMode mode) {
  return featureConfig[mode] ?? {};
}

/// Get all enabled features for a mode
List<Feature> getEnabledFeatures(dynamic profile) {
  return Feature.values.where((f) => useFeature(f, profile)).toList();
}

// ============================================================================
// Extension for UserProfile
// ============================================================================

/// Interface for objects that have features
abstract class HasFeatures {
  bool hasFeature(Feature feature);
}

/// Extension to add feature checks to UserProfile
extension UserProfileFeatures on dynamic {
  /// Check if profile has a specific feature
  /// 
  /// Usage:
  /// ```dart
  /// profile.hasFeature(Feature.quickSale)
  /// appState.profile.hasFeature(Feature.hpp)
  /// ```
  bool hasFeature(Feature feature) {
    if (this is HasFeatures) {
      return (this as HasFeatures).hasFeature(feature);
    }
    return false;
  }
  
  /// Get business mode from profile
  BusinessMode? get businessMode {
    if (this is HasFeatures) {
      final profile = this as HasFeatures;
      // Infer mode from enabled features
      if (profile.hasFeature(Feature.production)) {
        return BusinessMode.production;
      }
      if (profile.hasFeature(Feature.quickSale) || 
          profile.hasFeature(Feature.topCategories)) {
        return BusinessMode.store;
      }
      return BusinessMode.personal;
    }
    return null;
  }
  
  /// Check if in business mode (non-personal)
  bool get isBusinessMode {
    return Feature.values.any((f) => useFeature(f, this));
  }
}

// ============================================================================
// Legacy Support - Backward Compatibility
// ============================================================================

/// Default feature values when only isBusinessMode is known
const Map<Feature, bool> _featureDefaults = {
  Feature.product: false,
  Feature.outlets: false,
  Feature.budget: false,
  Feature.production: false,
  Feature.quickSale: true,
  Feature.topCategories: true,
  Feature.busiestDay: true,
  Feature.stock: true,
  Feature.productAnalytics: true,
  Feature.debt: false,
};

/// Convert legacy isBusinessMode to BusinessMode
BusinessMode modeFromBusinessMode(bool isBusiness) {
  return isBusiness ? BusinessMode.store : BusinessMode.personal;
}

/// Check if mode is business mode
bool isBusinessMode(BusinessMode mode) {
  return mode != BusinessMode.personal;
}

// ============================================================================
// Feature Mapping - For User Request
// ============================================================================

/// Map user request keys to Feature enum
const Map<String, Feature> featureMapping = {
  'fast_sale': Feature.quickSale,
  'top_products': Feature.topCategories,
  'inventory': Feature.production,
  'hpp': Feature.product,
  'stok_barang': Feature.stock,
  'analitik_produk': Feature.productAnalytics,
  'utang_piutang': Feature.debt,
};

/// Get Feature from user request key
Feature? featureFromKey(String key) {
  return featureMapping[key.toLowerCase()];
}
