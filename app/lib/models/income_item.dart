class IncomeItem {
  final String id;
  final String name;
  final double plannedAmount;
  final double receivedAmount;

  const IncomeItem({
    required this.id,
    required this.name,
    this.plannedAmount = 0.0,
    this.receivedAmount = 0.0,
  });

  IncomeItem copyWith({
    String? id,
    String? name,
    double? plannedAmount,
    double? receivedAmount,
  }) {
    return IncomeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
    );
  }
}