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
  final _incomeNameController = TextEditingController(text: 'Paycheck 1');
  final _incomeAmountController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _incomeNameController.dispose();
    _incomeAmountController.dispose();
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
    
    final incomeAmount = double.tryParse(_incomeAmountController.text) ?? 0.0;
    final incomeName = _incomeNameController.text.trim().isEmpty ? 'Paycheck 1' : _incomeNameController.text.trim();
    final defaultCategories = ref.read(defaultCategoriesProvider);
    
    final newBudget = Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: _startDate!,
      endDate: _endDate!,
      incomes: [
        IncomeItem(id: 'inc_${DateTime.now().millisecondsSinceEpoch}', name: incomeName, plannedAmount: incomeAmount, receivedAmount: 0.0),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Text(
                      _startDate == null 
                        ? 'Select Date Range' 
                        : '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Initial Income Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            TextField(
              controller: _incomeNameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Paycheck 1',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Initial Income Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            TextField(
              controller: _incomeAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g., 2000',
                prefixText: '£ ',
              ),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _saveBudget,
              child: const Text('Create Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}