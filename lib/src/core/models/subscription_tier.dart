import '../config/feature_config.dart';

/// Tier langganan — menentukan fitur mana yang bisa diakses user.
///
/// Urutan: free < retail < production (kumulatif ke atas).
enum SubscriptionTier {
  free('free', 'Gratis', 0),
  retail('retail', 'Retail', 19000),
  production('production', 'Produsen', 49000);

  const SubscriptionTier(this.value, this.label, this.pricePerMonth);

  final String value;
  final String label;

  /// Harga bulanan dalam rupiah (0 = gratis selamanya).
  final int pricePerMonth;

  static SubscriptionTier fromString(String? value) {
    return SubscriptionTier.values.firstWhere(
      (t) => t.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }

  /// Semua fitur yang boleh diakses di tier ini.
  Set<Feature> get allowedFeatures {
    switch (this) {
      case SubscriptionTier.free:
        return {Feature.budget, Feature.recurring};
      case SubscriptionTier.retail:
        return {
          Feature.budget,
          Feature.recurring,
          Feature.quickSale,
          Feature.topCategories,
          Feature.busiestDay,
          Feature.stock,
          Feature.productAnalytics,
          Feature.debt,
        };
      case SubscriptionTier.production:
        return Feature.values.toSet();
    }
  }

  bool allows(Feature feature) => allowedFeatures.contains(feature);

  bool get isPaid => pricePerMonth > 0;
}
