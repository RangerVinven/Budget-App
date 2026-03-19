import 'category_group.dart';
import 'income_item.dart';

class Budget {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<IncomeItem> incomes;
  final List<CategoryGroup> categoryGroups;

  const Budget({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.incomes = const [],
    this.categoryGroups = const [],
  });

  double get totalIncome => incomes.fold(0.0, (sum, item) => sum + item.plannedAmount);
  double get totalReceived => incomes.fold(0.0, (sum, item) => sum + item.receivedAmount);

  Budget copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    List<IncomeItem>? incomes,
    List<CategoryGroup>? categoryGroups,
  }) {
    return Budget(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      incomes: incomes ?? this.incomes,
      categoryGroups: categoryGroups ?? this.categoryGroups,
    );
  }
}