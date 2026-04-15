enum DateRangeType { day, week, month }

class Summary {
  const Summary({required this.totalIncome, required this.totalExpense});

  final int totalIncome;
  final int totalExpense;

  int get netProfit => totalIncome - totalExpense;
}
