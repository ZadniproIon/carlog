import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/category_chart.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/summary_card.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({
    super.key,
    required this.vehicles,
    required this.expenses,
    required this.reminders,
    required this.onAddVehicle,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final VoidCallback onAddVehicle;
  final ValueChanged<Vehicle> onEditVehicle;
  final ValueChanged<String> onDeleteVehicle;
  final ValueChanged<String> onAddReminder;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            tooltip: 'Add vehicle',
            onPressed: onAddVehicle,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles yet. Add your first one.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => VehicleDetailScreen(
                          vehicle: vehicle,
                          expenses: expenses,
                          reminders: reminders,
                          onEditVehicle: onEditVehicle,
                          onDeleteVehicle: onDeleteVehicle,
                          onAddReminder: onAddReminder,
                          onEditReminder: onEditReminder,
                          onDeleteReminder: onDeleteReminder,
                          onEditExpense: onEditExpense,
                          onDeleteExpense: onDeleteExpense,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car_filled_outlined),
                              const SizedBox(width: 8),
                              Text(
                                vehicle.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Text(
                                '${vehicle.mileage} km',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    onEditVehicle(vehicle);
                                  } else if (value == 'delete') {
                                    onDeleteVehicle(vehicle.id);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _InfoChip(
                                label: 'Year ${vehicle.year}',
                                icon: Icons.calendar_today_outlined,
                              ),
                              _InfoChip(
                                label: vehicle.engine,
                                icon: Icons.speed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      label: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    );
  }
}

class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    required this.expenses,
    required this.reminders,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final Vehicle vehicle;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final ValueChanged<Vehicle> onEditVehicle;
  final ValueChanged<String> onDeleteVehicle;
  final ValueChanged<String> onAddReminder;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final vehicleExpenses = expenses
        .where((e) => e.vehicleId == vehicle.id)
        .toList();
    final vehicleReminders =
        reminders.where((r) => r.vehicleId == vehicle.id).toList()
          ..sort((a, b) {
            final aDate = a.dueDate ?? DateTime(9999);
            final bDate = b.dueDate ?? DateTime(9999);
            return aDate.compareTo(bDate);
          });

    final totalSpent = vehicleExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    vehicleExpenses.sort((a, b) => b.date.compareTo(a.date));
    final lastExpense = vehicleExpenses.isNotEmpty
        ? vehicleExpenses.first
        : null;

    final categoryTotals = <ExpenseCategory, double>{};
    for (final e in vehicleExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final now = DateTime.now();
    final expensesLast30Days = vehicleExpenses
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 30))))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${vehicle.displayName} - ${vehicle.year}'),
        actions: [
          IconButton(
            tooltip: 'Edit vehicle',
            onPressed: () => onEditVehicle(vehicle),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete vehicle',
            onPressed: () {
              onDeleteVehicle(vehicle.id);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onAddReminder(vehicle.id),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Add reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Header',
              icon: Icons.directions_car_filled_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle.year} - ${vehicle.engine}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Specs',
              icon: Icons.tune,
              child: Column(
                children: [
                  _SpecRow(label: 'Year', value: '${vehicle.year}'),
                  _SpecRow(label: 'Engine', value: vehicle.engine),
                  _SpecRow(
                    label: 'Current mileage',
                    value: '${vehicle.mileage} km',
                  ),
                  _SpecRow(label: 'VIN', value: vehicle.vin),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Status',
              icon: Icons.monitor_heart_outlined,
              child: Column(
                children: [
                  _SpecRow(
                    label: 'Last expense date',
                    value: lastExpense == null
                        ? 'No expense history'
                        : _formatDate(lastExpense.date),
                  ),
                  _SpecRow(
                    label: 'Expenses in last 30 days',
                    value: '$expensesLast30Days',
                  ),
                  _SpecRow(
                    label: 'Open maintenance reminders',
                    value: '${vehicleReminders.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Total spent',
                    value: '${totalSpent.toStringAsFixed(0)} lei',
                    subtitle: '${vehicleExpenses.length} expenses',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'Latest mileage',
                    value: '${vehicle.mileage} km',
                    subtitle: lastExpense == null
                        ? 'No history yet'
                        : 'Last at ${lastExpense.mileage} km',
                    icon: Icons.speed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CategoryChart(categoryTotals: categoryTotals),
            const SizedBox(height: 16),
            Text(
              'Maintenance for this vehicle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (vehicleReminders.isEmpty)
              const Text('No maintenance reminders set.')
            else
              _VehicleMaintenanceList(
                reminders: vehicleReminders,
                onEditReminder: onEditReminder,
                onDeleteReminder: onDeleteReminder,
              ),
            const SizedBox(height: 16),
            Text(
              'Expense history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (vehicleExpenses.isEmpty)
              const Text('No expenses recorded for this vehicle yet.')
            else
              Column(
                children: vehicleExpenses.map((expense) {
                  return ExpenseListTile(
                    expense: expense,
                    vehicle: vehicle,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEditExpense(expense);
                        } else if (value == 'delete') {
                          onDeleteExpense(expense.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleMaintenanceList extends StatelessWidget {
  const _VehicleMaintenanceList({
    required this.reminders,
    required this.onEditReminder,
    required this.onDeleteReminder,
  });

  final List<MaintenanceReminder> reminders;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: reminders.map((r) {
        final dueInfo = _buildDueInfo(r);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(Icons.build_circle_outlined, color: scheme.primary),
            title: Text(r.title),
            subtitle: Text('$dueInfo\n${r.description}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEditReminder(r);
                } else if (value == 'delete') {
                  onDeleteReminder(r.id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _buildDueInfo(MaintenanceReminder reminder) {
    if (reminder.dueDate != null) {
      final date = reminder.dueDate!;
      return 'Due on ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    if (reminder.dueMileage != null) {
      return 'Due at ${reminder.dueMileage} km';
    }
    return 'No due information';
  }
}
