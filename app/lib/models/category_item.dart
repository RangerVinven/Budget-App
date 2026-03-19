class CategoryItem {
  final String id;
  final String name;
  final double plannedAmount;
  final double spentAmount;

  const CategoryItem({
    required this.id,
    required this.name,
    this.plannedAmount = 0.0,
    this.spentAmount = 0.0,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'],
      name: json['name'],
      plannedAmount: (json['planned_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planned_amount': plannedAmount,
      'spent_amount': spentAmount,
    };
  }

  CategoryItem copyWith({
    String? id,
    String? name,
    double? plannedAmount,
    double? spentAmount,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }
}