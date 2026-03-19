import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: budgets.isEmpty
          ? const Center(child: Text('No budgets yet. Create one!', style: TextStyle(color: Colors.black54)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final dateFormat = DateFormat('MMM d, yyyy');
                final dateRange = '${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(selectedBudgetProvider.notifier).selectBudget(budget.id);
                      context.push('/dashboard/budget');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Income: \$${budget.totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black26),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/create-budget'),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }
}