import '../models/space_model.dart';

class SpaceFeatures {
  static bool canUseQuickSale(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.store && isPremium;

  // Store dan production bisa utang-piutang
  static bool canUseDebt(SpaceModel? space, bool isPremium) =>
      space?.type != SpaceType.personal && isPremium;

  // HPP calculator — production only
  static bool canUseHpp(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.production && isPremium;

  // Bahan baku & batch produksi — production only
  static bool canUseProductionBatch(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.production && isPremium;

  // Multi-outlet — store dan production
  static bool canUseOutlets(SpaceModel? space, bool isPremium) =>
      (space?.type == SpaceType.store ||
          space?.type == SpaceType.production) &&
      isPremium;

  // Budget — personal gratis (Premium Pribadi v3+ TBD), production perlu premium
  static bool canUseBudget(SpaceModel? space, bool isPremium) {
    if (space?.type == SpaceType.personal) return true;
    if (space?.type == SpaceType.production) return isPremium;
    return false;
  }

  // Stok barang — store only
  static bool canUseStock(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.store && isPremium;

  // Analitik produk — store dan production
  static bool canUseProductAnalytics(SpaceModel? space, bool isPremium) =>
      space?.type != SpaceType.personal && isPremium;

  // Insight: kategori terlaris — store only
  static bool canUseTopCategories(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.store && isPremium;

  // Insight: hari tersibuk — store only
  static bool canUseBusiestDay(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.store && isPremium;

  // Transaksi berulang — semua space gratis (Premium Pribadi v3+ TBD)
  static bool canUseRecurring(SpaceModel? space, bool isPremium) => true;
}
