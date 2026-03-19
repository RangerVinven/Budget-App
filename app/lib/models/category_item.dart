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