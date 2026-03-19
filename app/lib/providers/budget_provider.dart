import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/category_group.dart';
import '../models/category_item.dart';
import '../models/income_item.dart';

const baseUrl = 'http://localhost:8080/api';

class ApiClient {
  final Dio dio = Dio();

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }
}

final apiClientProvider = Provider((ref) => ApiClient());

class BudgetNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    // We start with an empty list and fetch when needed or on init
    _fetchBudgets();
    return [];
  }

  Future<void> _fetchBudgets() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('$baseUrl/budgets');
      final List<dynamic> data = response.data;
      
      final budgets = await Future.wait(data.map((b) async {
        final detailResponse = await client.dio.get('$baseUrl/budgets/${b['id']}');
        return Budget.fromJson(detailResponse.data);
      }));
      
      state = budgets;
    } catch (e) {
      print('Error fetching budgets: $e');
    }
  }

  Future<void> addBudget(Budget budget) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('$baseUrl/budgets', data: budget.toJson());
      final newBudget = Budget.fromJson(response.data);
      state = [...state, newBudget];
    } catch (e) {
      print('Error adding budget: $e');
    }
  }

  Future<void> addIncome(String budgetId, IncomeItem income) async {
    try {
      final client = ref.read(apiClientProvider);
      final data = income.toJson();
      data['budget_id'] = budgetId;
      final response = await client.dio.post('$baseUrl/incomes', data: data);
      final newIncome = IncomeItem.fromJson(response.data);
      
      state = state.map((b) {
        if (b.id != budgetId) return b;
        return b.copyWith(incomes: [...b.incomes, newIncome]);
      }).toList();
    } catch (e) {
      print('Error adding income: $e');
    }
  }

  Future<void> updateIncome(String budgetId, String incomeId, {double? plannedAmount, double? receivedAmount, String? name}) async {
    try {
      final client = ref.read(apiClientProvider);
      final budget = state.firstWhere((b) => b.id == budgetId);
      final income = budget.incomes.firstWhere((i) => i.id == incomeId);
      
      final updated = income.copyWith(
        plannedAmount: plannedAmount ?? income.plannedAmount,
        receivedAmount: receivedAmount ?? income.receivedAmount,
        name: name ?? income.name,
      );

      await client.dio.patch('$baseUrl/incomes/$incomeId', data: updated.toJson());
      
      state = state.map((b) {
        if (b.id != budgetId) return b;
        final updatedIncomes = b.incomes.map((inc) {
          if (inc.id != incomeId) return inc;
          return updated;
        }).toList();
        return b.copyWith(incomes: updatedIncomes);
      }).toList();
    } catch (e) {
      print('Error updating income: $e');
    }
  }

  Future<void> updateCategoryItem(String budgetId, String groupId, String itemId, {double? plannedAmount, double? spentAmount, String? name}) async {
    try {
      final client = ref.read(apiClientProvider);
      final budget = state.firstWhere((b) => b.id == budgetId);
      final group = budget.categoryGroups.firstWhere((g) => g.id == groupId);
      final item = group.items.firstWhere((i) => i.id == itemId);
      
      final updated = item.copyWith(
        plannedAmount: plannedAmount ?? item.plannedAmount,
        spentAmount: spentAmount ?? item.spentAmount,
        name: name ?? item.name,
      );

      await client.dio.patch('$baseUrl/items/$itemId', data: updated.toJson());

      state = state.map((b) {
        if (b.id != budgetId) return b;
        final updatedGroups = b.categoryGroups.map((g) {
          if (g.id != groupId) return g;
          final updatedItems = g.items.map((i) {
            if (i.id != itemId) return i;
            return updated;
          }).toList();
          return g.copyWith(items: updatedItems);
        }).toList();
        return b.copyWith(categoryGroups: updatedGroups);
      }).toList();
    } catch (e) {
      print('Error updating item: $e');
    }
  }

  Future<void> addCategoryItem(String budgetId, String groupId, CategoryItem item) async {
    try {
      final client = ref.read(apiClientProvider);
      final data = item.toJson();
      data['group_id'] = groupId;
      final response = await client.dio.post('$baseUrl/items', data: data);
      final newItem = CategoryItem.fromJson(response.data);

      state = state.map((b) {
        if (b.id != budgetId) return b;
        final updatedGroups = b.categoryGroups.map((g) {
          if (g.id != groupId) return g;
          return g.copyWith(items: [...g.items, newItem]);
        }).toList();
        return b.copyWith(categoryGroups: updatedGroups);
      }).toList();
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  Future<void> updateCategoryGroup(String budgetId, String groupId, {String? name}) async {
    try {
      final client = ref.read(apiClientProvider);
      final budget = state.firstWhere((b) => b.id == budgetId);
      final group = budget.categoryGroups.firstWhere((g) => g.id == groupId);
      
      final updated = group.copyWith(name: name ?? group.name);
      await client.dio.patch('$baseUrl/groups/$groupId', data: updated.toJson());

      state = state.map((b) {
        if (b.id != budgetId) return b;
        final updatedGroups = b.categoryGroups.map((g) {
          if (g.id != groupId) return g;
          return updated;
        }).toList();
        return b.copyWith(categoryGroups: updatedGroups);
      }).toList();
    } catch (e) {
      print('Error updating group: $e');
    }
  }

  Future<void> addCategoryGroup(String budgetId, CategoryGroup group) async {
    try {
      final client = ref.read(apiClientProvider);
      final data = group.toJson();
      data['budget_id'] = budgetId;
      final response = await client.dio.post('$baseUrl/groups', data: data);
      final newGroup = CategoryGroup.fromJson(response.data);

      state = state.map((b) {
        if (b.id != budgetId) return b;
        return b.copyWith(categoryGroups: [...b.categoryGroups, newGroup]);
      }).toList();
    } catch (e) {
      print('Error adding group: $e');
    }
  }
}

final budgetsProvider = NotifierProvider<BudgetNotifier, List<Budget>>(BudgetNotifier.new);

class SelectedBudgetNotifier extends Notifier<String?> {
  @override
  String? build() {
    final budgets = ref.watch(budgetsProvider);
    if (budgets.isNotEmpty && state == null) {
      return budgets.first.id;
    }
    return state;
  }

  void selectBudget(String? id) {
    state = id;
  }
}

final selectedBudgetProvider = NotifierProvider<SelectedBudgetNotifier, String?>(SelectedBudgetNotifier.new);

final currentBudgetProvider = Provider<Budget?>((ref) {
  final budgets = ref.watch(budgetsProvider);
  final selectedId = ref.watch(selectedBudgetProvider);
  if (selectedId == null) return budgets.isNotEmpty ? budgets.first : null;
  try {
    return budgets.firstWhere((b) => b.id == selectedId);
  } catch (_) {
    return budgets.isNotEmpty ? budgets.first : null;
  }
});