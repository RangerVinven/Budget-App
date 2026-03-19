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
          ? const Center(child: Text('No budgets yet. Create one!'))
          : ListView.builder(
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final dateFormat = DateFormat('MMM d, yyyy');
                final dateRange = '${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(dateRange, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Income: \$${budget.totalIncome.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(selectedBudgetProvider.notifier).selectBudget(budget.id);
                      context.push('/dashboard/budget');
                    },
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