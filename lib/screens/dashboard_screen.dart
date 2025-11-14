import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/category_chart.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.vehicles,
    required this.expenses,
    required this.reminders,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();

    final totalThisMonth =
        monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    final categoryTotals = <ExpenseCategory, double>{};
    for (final e in monthExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final recentExpenses = expenses.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good to see you 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Here is an overview of your cars.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'This month',
                    value: '${totalThisMonth.toStringAsFixed(0)} lei',
                    subtitle: '${monthExpenses.length} expenses',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'Vehicles',
                    value: '${vehicles.length}',
                    subtitle: 'Tracked in this demo',
                    icon: Icons.directions_car_filled_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CategoryChart(categoryTotals: categoryTotals),
            const SizedBox(height: 16),
            Text(
              'Upcoming maintenance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _MaintenanceList(
              reminders: reminders,
              vehicles: vehicles,
            ),
            const SizedBox(height: 16),
            Text(
              'Recent expenses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (recentExpenses.isEmpty)
              const Text('No expenses yet. Add your first one!')
            else
              Column(
                children: recentExpenses
                    .map(
                      (e) => ExpenseListTile(
                        expense: e,
                        vehicle: vehicles
                            .where((v) => v.id == e.vehicleId)
                            .firstOrNull,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({
    required this.reminders,
    required this.vehicles,
  });

  final List<MaintenanceReminder> reminders;
  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const Text('No reminders in this demo.');
    }

    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: reminders.map((r) {
        final vehicle =
            vehicles.where((v) => v.id == r.vehicleId).firstOrNull;
        final dueInfo = _buildDueInfo(r);
        return Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.schedule, color: scheme.primary),
            title: Text(r.title),
            subtitle: Text(
              '${vehicle?.displayName ?? 'Vehicle'} • $dueInfo\n${r.description}',
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  String _buildDueInfo(MaintenanceReminder reminder) {
    if (reminder.dueDate != null) {
      final date = reminder.dueDate!;
      return 'Due on ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
    if (reminder.dueMileage != null) {
      return 'Due at ${reminder.dueMileage} km';
    }
    return 'No due information';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
