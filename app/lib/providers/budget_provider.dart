import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/category_group.dart';
import '../models/category_item.dart';
import '../models/income_item.dart';

// Mock initial data
final _initialBudgets = [
  Budget(
    id: 'b1',
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
    incomes: [
      const IncomeItem(id: 'inc1', name: 'Paycheck 1', plannedAmount: 2000.0, receivedAmount: 2000.0),
      const IncomeItem(id: 'inc2', name: 'Paycheck 2', plannedAmount: 2000.0, receivedAmount: 2000.0),
    ],
    categoryGroups: [
      const CategoryGroup(
        id: 'cg1',
        name: 'Giving',
        items: [
          CategoryItem(id: 'ci1', name: 'Charity', plannedAmount: 400.0, spentAmount: 400.0),
        ],
      ),
      const CategoryGroup(
        id: 'cg2',
        name: 'Housing',
        items: [
          CategoryItem(id: 'ci2', name: 'Rent', plannedAmount: 1500.0, spentAmount: 1500.0),
          CategoryItem(id: 'ci3', name: 'Water', plannedAmount: 50.0, spentAmount: 45.0),
        ],
      ),
      const CategoryGroup(
        id: 'cg3',
        name: 'Food',
        items: [
          CategoryItem(id: 'ci4', name: 'Groceries', plannedAmount: 400.0, spentAmount: 320.0),
          CategoryItem(id: 'ci5', name: 'Restaurants', plannedAmount: 150.0, spentAmount: 100.0),
        ],
      ),
    ],
  )
];

class BudgetNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    return _initialBudgets;
  }

  void addBudget(Budget budget) {
    state = [...state, budget];
  }

  void addIncome(String budgetId, IncomeItem income) {
    state = state.map((b) {
      if (b.id != budgetId) return b;
      return b.copyWith(incomes: [...b.incomes, income]);
    }).toList();
  }

  void updateIncome(String budgetId, String incomeId, {double? plannedAmount, double? receivedAmount, String? name}) {
    state = state.map((b) {
      if (b.id != budgetId) return b;
      final updatedIncomes = b.incomes.map((inc) {
        if (inc.id != incomeId) return inc;
        return inc.copyWith(
          plannedAmount: plannedAmount ?? inc.plannedAmount,
          receivedAmount: receivedAmount ?? inc.receivedAmount,
          name: name ?? inc.name,
        );
      }).toList();
      return b.copyWith(incomes: updatedIncomes);
    }).toList();
  }

  void updateCategoryItem(String budgetId, String groupId, String itemId, {double? plannedAmount, double? spentAmount, String? name}) {
    state = state.map((b) {
      if (b.id != budgetId) return b;

      final updatedGroups = b.categoryGroups.map((g) {
        if (g.id != groupId) return g;

        final updatedItems = g.items.map((i) {
          if (i.id != itemId) return i;
          return i.copyWith(
            plannedAmount: plannedAmount ?? i.plannedAmount,
            spentAmount: spentAmount ?? i.spentAmount,
            name: name ?? i.name,
          );
        }).toList();

        return g.copyWith(items: updatedItems);
      }).toList();

      return b.copyWith(categoryGroups: updatedGroups);
    }).toList();
  }

  void addCategoryItem(String budgetId, String groupId, CategoryItem item) {
    state = state.map((b) {
      if (b.id != budgetId) return b;
      final updatedGroups = b.categoryGroups.map((g) {
        if (g.id != groupId) return g;
        return g.copyWith(items: [...g.items, item]);
      }).toList();
      return b.copyWith(categoryGroups: updatedGroups);
    }).toList();
  }

  void updateCategoryGroup(String budgetId, String groupId, {String? name}) {
    state = state.map((b) {
      if (b.id != budgetId) return b;
      final updatedGroups = b.categoryGroups.map((g) {
        if (g.id != groupId) return g;
        return g.copyWith(name: name ?? g.name);
      }).toList();
      return b.copyWith(categoryGroups: updatedGroups);
    }).toList();
  }

  void addCategoryGroup(String budgetId, CategoryGroup group) {
    state = state.map((b) {
      if (b.id != budgetId) return b;
      return b.copyWith(categoryGroups: [...b.categoryGroups, group]);
    }).toList();
  }
}

final budgetsProvider = NotifierProvider<BudgetNotifier, List<Budget>>(BudgetNotifier.new);

class SelectedBudgetNotifier extends Notifier<String?> {
  @override
  String? build() => _initialBudgets.first.id;

  void selectBudget(String? id) {
    state = id;
  }
}

final selectedBudgetProvider = NotifierProvider<SelectedBudgetNotifier, String?>(SelectedBudgetNotifier.new);

final currentBudgetProvider = Provider<Budget?>((ref) {
  final budgets = ref.watch(budgetsProvider);
  final selectedId = ref.watch(selectedBudgetProvider);
  if (selectedId == null) return null;
  try {
    return budgets.firstWhere((b) => b.id == selectedId);
  } catch (_) {
    return budgets.isNotEmpty ? budgets.first : null;
  }
});