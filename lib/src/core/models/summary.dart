enum DateRangeType { day, week, month }

class Summary {
  const Summary({
    required this.totalIncome,
    required this.totalExpense,
    this.stockExpense = 0,
  });

  final int totalIncome;
  final int totalExpense;

  /// Pengeluaran yang berasal dari kategori bertanda isStockPurchase.
  final int stockExpense;

  int get netProfit => totalIncome - totalExpense;

  /// Pengeluaran operasional murni (di luar pembelian stok).
  int get operatingExpense => totalExpense - stockExpense;
}
