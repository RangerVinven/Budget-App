import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../models/category_item.dart';
import '../models/category_group.dart';
import '../models/income_item.dart';

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(currentBudgetProvider);

    if (budget == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget')),
        body: const Center(child: Text('Budget not found')),
      );
    }

    // Calculate totals
    double totalPlanned = 0.0;
    for (var group in budget.categoryGroups) {
      for (var item in group.items) {
        totalPlanned += item.plannedAmount;
      }
    }
    
    final leftToBudget = budget.totalIncome - totalPlanned;

    return DefaultTabController(
      initialIndex: 1, // Default to 'Spent' tab
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(DateFormat('MMMM yyyy').format(budget.startDate)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Planned'),
              Tab(text: 'Spent'),
              Tab(text: 'Remaining'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Header Stats - Sticky
            Container(
              padding: const EdgeInsets.all(24.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Income', style: TextStyle(fontSize: 12)),
                      Text('\$${budget.totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(leftToBudget >= 0 ? 'Left to Budget' : 'Overbudget', style: const TextStyle(fontSize: 12)),
                      Text(
                        '\$${leftToBudget.abs().toStringAsFixed(2)}', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 24,
                          color: leftToBudget >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tab Views
            const Expanded(
              child: TabBarView(
                children: [
                  _BudgetList(tab: _TabType.planned),
                  _BudgetList(tab: _TabType.spent),
                  _BudgetList(tab: _TabType.remaining),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddTransactionDialog(context, ref, budget);
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add Transaction'),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref, Budget budget) {
    String? selectedGroupId;
    String? selectedItemId;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final items = selectedGroupId == null
              ? <CategoryItem>[]
              : budget.categoryGroups.firstWhere((g) => g.id == selectedGroupId).items;

          return AlertDialog(
            title: const Text('Add Transaction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select Group'),
                  value: selectedGroupId,
                  items: budget.categoryGroups.map((g) {
                    return DropdownMenuItem(value: g.id, child: Text(g.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedGroupId = val;
                      selectedItemId = null; // Reset item when group changes
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select Category'),
                  value: selectedItemId,
                  items: items.map((i) {
                    return DropdownMenuItem(value: i.id, child: Text(i.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedItemId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  if (selectedGroupId != null && selectedItemId != null && amountController.text.isNotEmpty) {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0) {
                      final item = budget.categoryGroups.firstWhere((g) => g.id == selectedGroupId).items.firstWhere((i) => i.id == selectedItemId);
                      final newSpent = item.spentAmount + amount;
                      ref.read(budgetsProvider.notifier).updateCategoryItem(budget.id, selectedGroupId!, selectedItemId!, spentAmount: newSpent);
                    }
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}

enum _TabType { planned, spent, remaining }

class _BudgetList extends ConsumerWidget {
  final _TabType tab;

  const _BudgetList({required this.tab});

  void _showAddCategoryGroupDialog(BuildContext context, WidgetRef ref, String budgetId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newGroup = CategoryGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text.trim(),
                );
                ref.read(budgetsProvider.notifier).addCategoryGroup(budgetId, newGroup);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context, WidgetRef ref, String budgetId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income Source'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Income Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newIncome = IncomeItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text.trim(),
                );
                ref.read(budgetsProvider.notifier).addIncome(budgetId, newIncome);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, String budgetId, String groupId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Item Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newItem = CategoryItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text.trim(),
                );
                ref.read(budgetsProvider.notifier).addCategoryItem(budgetId, groupId, newItem);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryGroupDialog(BuildContext context, WidgetRef ref, String budgetId, CategoryGroup group) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(budgetsProvider.notifier).updateCategoryGroup(budgetId, group.id, name: controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryItemDialog(BuildContext context, WidgetRef ref, String budgetId, String groupId, CategoryItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Item Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(budgetsProvider.notifier).updateCategoryItem(budgetId, groupId, item.id, name: controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditIncomeDialog(BuildContext context, WidgetRef ref, String budgetId, IncomeItem income) {
    final controller = TextEditingController(text: income.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Income Source'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Income Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(budgetsProvider.notifier).updateIncome(budgetId, income.id, name: controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(currentBudgetProvider);
    if (budget == null) return const SizedBox();

    return ListView(
      children: [
        // INCOME SECTION
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'INCOME',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...budget.incomes.map((income) {
          return _IncomeRow(
            budget: budget,
            income: income,
            tab: tab,
            onEditName: tab == _TabType.planned ? () => _showEditIncomeDialog(context, ref, budget.id, income) : null,
          );
        }),
        if (tab == _TabType.planned)
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Income'),
            onTap: () => _showAddIncomeDialog(context, ref, budget.id),
          ),
        const Divider(),

        // CATEGORY GROUPS
        ...budget.categoryGroups.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: GestureDetector(
                  onTap: tab == _TabType.planned ? () => _showEditCategoryGroupDialog(context, ref, budget.id, group) : null,
                  child: Text(
                    group.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              ...group.items.map((item) {
                return _CategoryRow(
                  budget: budget,
                  groupId: group.id,
                  item: item,
                  tab: tab,
                  onEditName: tab == _TabType.planned ? () => _showEditCategoryItemDialog(context, ref, budget.id, group.id, item) : null,
                );
              }),
              if (tab == _TabType.planned)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Item'),
                  onTap: () => _showAddItemDialog(context, ref, budget.id, group.id),
                ),
              const Divider(),
            ],
          );
        }),

        // Add Category Group
        if (tab == _TabType.planned)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () => _showAddCategoryGroupDialog(context, ref, budget.id),
              icon: const Icon(Icons.add),
              label: const Text('Add Category Group'),
            ),
          ),
        const SizedBox(height: 48), // Padding at the bottom
      ],
    );
  }
}

class _IncomeRow extends ConsumerStatefulWidget {
  final Budget budget;
  final IncomeItem income;
  final _TabType tab;
  final VoidCallback? onEditName;

  const _IncomeRow({
    required this.budget,
    required this.income,
    required this.tab,
    this.onEditName,
  });

  @override
  ConsumerState<_IncomeRow> createState() => _IncomeRowState();
}

class _IncomeRowState extends ConsumerState<_IncomeRow> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveValue();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _IncomeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.income != widget.income || oldWidget.tab != widget.tab) {
      if (!_focusNode.hasFocus) {
        _initController();
      }
    }
  }

  void _initController() {
    double value = 0.0;
    if (widget.tab == _TabType.planned) {
      value = widget.income.plannedAmount;
    } else if (widget.tab == _TabType.spent) {
      value = widget.income.receivedAmount;
    }
    _controller = TextEditingController(text: value == 0.0 ? '' : value.toStringAsFixed(2));
  }

  void _saveValue() {
    final val = double.tryParse(_controller.text) ?? 0.0;
    if (widget.tab == _TabType.planned && val != widget.income.plannedAmount) {
      ref.read(budgetsProvider.notifier).updateIncome(widget.budget.id, widget.income.id, plannedAmount: val);
    } else if (widget.tab == _TabType.spent && val != widget.income.receivedAmount) {
      ref.read(budgetsProvider.notifier).updateIncome(widget.budget.id, widget.income.id, receivedAmount: val);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tab == _TabType.remaining) {
      final val = widget.income.receivedAmount - widget.income.plannedAmount;
      return ListTile(
        title: Text(widget.income.name),
        trailing: Text(
          '\$${val.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: val < 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return ListTile(
      title: GestureDetector(
        onTap: widget.onEditName,
        child: Text(widget.income.name, style: widget.onEditName != null ? TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline) : null),
      ),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            prefixText: '\$',
            border: UnderlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          onSubmitted: (_) => _focusNode.unfocus(),
        ),
      ),
    );
  }
}

class _CategoryRow extends ConsumerStatefulWidget {
  final Budget budget;
  final String groupId;
  final CategoryItem item;
  final _TabType tab;
  final VoidCallback? onEditName;

  const _CategoryRow({
    required this.budget,
    required this.groupId,
    required this.item,
    required this.tab,
    this.onEditName,
  });

  @override
  ConsumerState<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends ConsumerState<_CategoryRow> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveValue();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CategoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item || oldWidget.tab != widget.tab) {
      if (!_focusNode.hasFocus) {
        _initController();
      }
    }
  }

  void _initController() {
    double value = 0.0;
    if (widget.tab == _TabType.planned) {
      value = widget.item.plannedAmount;
    } else if (widget.tab == _TabType.spent) {
      value = widget.item.spentAmount;
    }
    _controller = TextEditingController(text: value == 0.0 ? '' : value.toStringAsFixed(2));
  }

  void _saveValue() {
    final val = double.tryParse(_controller.text) ?? 0.0;
    if (widget.tab == _TabType.planned && val != widget.item.plannedAmount) {
      ref.read(budgetsProvider.notifier).updateCategoryItem(widget.budget.id, widget.groupId, widget.item.id, plannedAmount: val);
    } else if (widget.tab == _TabType.spent && val != widget.item.spentAmount) {
      ref.read(budgetsProvider.notifier).updateCategoryItem(widget.budget.id, widget.groupId, widget.item.id, spentAmount: val);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tab == _TabType.remaining) {
      final val = widget.item.plannedAmount - widget.item.spentAmount;
      return ListTile(
        title: Text(widget.item.name),
        trailing: Text(
          '\$${val.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: val < 0 ? Theme.of(context).colorScheme.error : (val > 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
      );
    }

    return ListTile(
      title: GestureDetector(
        onTap: widget.onEditName,
        child: Text(widget.item.name, style: widget.onEditName != null ? TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline) : null),
      ),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            prefixText: '\$',
            border: UnderlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          onSubmitted: (_) => _focusNode.unfocus(),
        ),
      ),
    );
  }
}