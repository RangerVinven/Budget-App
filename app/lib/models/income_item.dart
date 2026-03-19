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

  factory IncomeItem.fromJson(Map<String, dynamic> json) {
    return IncomeItem(
      id: json['id'],
      name: json['name'],
      plannedAmount: (json['planned_amount'] as num).toDouble(),
      receivedAmount: (json['received_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planned_amount': plannedAmount,
      'received_amount': receivedAmount,
    };
  }

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