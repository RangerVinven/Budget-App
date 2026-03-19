import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/income_item.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';

class CreateBudgetScreen extends ConsumerStatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _incomeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _saveBudget() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date range')));
      return;
    }
    
    final income = double.tryParse(_incomeController.text) ?? 0.0;
    final defaultCategories = ref.read(defaultCategoriesProvider);
    
    final newBudget = Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: _startDate!,
      endDate: _endDate!,
      incomes: [
        IncomeItem(id: 'inc_${DateTime.now().millisecondsSinceEpoch}', name: 'Paycheck 1', plannedAmount: income, receivedAmount: 0.0),
      ],
      categoryGroups: defaultCategories,
    );

    ref.read(budgetsProvider.notifier).addBudget(newBudget);
    ref.read(selectedBudgetProvider.notifier).selectBudget(newBudget.id);
    
    context.go('/dashboard/budget'); // Navigate to detail
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Scaffold(
      appBar: AppBar(title: const Text('Create Budget')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(_startDate == null 
                  ? 'Select Date Range' 
                  : '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'),
                onTap: () => _selectDateRange(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Expected Initial Income (e.g., Paycheck 1)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveBudget,
              child: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }
}