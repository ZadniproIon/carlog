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
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
      ),
      body: ListView.builder(
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
  const _InfoChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: scheme.primary,
      ),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    required this.expenses,
    required this.reminders,
  });

  final Vehicle vehicle;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;

  @override
  Widget build(BuildContext context) {
    final vehicleExpenses =
        expenses.where((e) => e.vehicleId == vehicle.id).toList();
    final vehicleReminders =
        reminders.where((r) => r.vehicleId == vehicle.id).toList();

    final totalSpent = vehicleExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    vehicleExpenses.sort((a, b) => b.date.compareTo(a.date));
    final lastExpense =
        vehicleExpenses.isNotEmpty ? vehicleExpenses.first : null;

    final categoryTotals = <ExpenseCategory, double>{};
    for (final e in vehicleExpenses) {
      categoryTotals[e.category] =
          (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final now = DateTime.now();
    final expensesLast30Days = vehicleExpenses
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 30))))
        .length;

    final aiInsight = _getVehicleAiInsight(vehicle);

    return Scaffold(
      appBar: AppBar(
        title: Text('${vehicle.displayName} · ${vehicle.year}'),
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
                    '${vehicle.year} • ${vehicle.engine}',
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
                  _SpecRow(label: 'Current mileage', value: '${vehicle.mileage} km'),
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
            const SizedBox(height: 12),
            _SectionCard(
              title: 'AI Insight',
              icon: Icons.auto_awesome,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aiInsight.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  ...aiInsight.bullets.map(
                    (bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle, size: 7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bullet,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-generated demo insight. Verify with owner manual and service documentation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
              _VehicleMaintenanceList(reminders: vehicleReminders),
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
                children: vehicleExpenses
                    .map(
                      (e) => ExpenseListTile(
                        expense: e,
                        vehicle: vehicle,
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

  _VehicleAiInsight _getVehicleAiInsight(Vehicle vehicle) {
    final key = '${vehicle.brand.toLowerCase()} ${vehicle.model.toLowerCase()}';

    if (key.contains('volkswagen') && key.contains('passat')) {
      return const _VehicleAiInsight(
        summary:
            'The Volkswagen Passat 2.0 TDI is generally a reliable long-distance daily driver when maintenance intervals are respected. It offers good fuel economy and predictable running costs for its class.',
        bullets: [
          'Common things to monitor: EGR valve, DPF load, and turbo actuator wear on higher mileage.',
          'Use quality oil and timely filter changes to reduce diesel system issues.',
          'Watch for suspension bush wear and dual-mass flywheel vibration as mileage grows.',
        ],
      );
    }

    if (key.contains('tesla') && key.contains('model 3')) {
      return const _VehicleAiInsight(
        summary:
            'Tesla Model 3 Long Range is considered a dependable EV drivetrain-wise, with low routine maintenance compared to combustion vehicles. Ownership experience is usually software- and tire-dependent.',
        bullets: [
          'Common things to monitor: tire wear (high torque), alignment, and occasional 12V battery/service alerts.',
          'Maintain tire pressure and rotate regularly to improve efficiency and tire lifespan.',
          'Track charging habits and preconditioning to reduce battery stress in extreme temperatures.',
        ],
      );
    }

    if (key.contains('porsche') && key.contains('cayenne')) {
      return const _VehicleAiInsight(
        summary:
            'Porsche Cayenne Hybrid is usually robust when serviced on schedule, but running costs can be high. It is reliable as a premium SUV if preventive maintenance is done consistently.',
        bullets: [
          'Common things to monitor: air suspension components, cooling system health, and hybrid battery system checks.',
          'Premium tires, brakes, and suspension consumables can significantly affect ownership costs.',
          'Follow official service intervals closely to avoid costly drivetrain and electronics issues.',
        ],
      );
    }

    return const _VehicleAiInsight(
      summary:
          'This model has a balanced reliability profile when maintained consistently. Preventive service and quality parts are the biggest factors for long-term cost control.',
      bullets: [
        'Monitor recurring repair categories and investigate patterns early.',
        'Respect service intervals and track major consumables.',
        'Keep records complete to improve resale value and maintenance planning.',
      ],
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
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
  const _SpecRow({
    required this.label,
    required this.value,
  });

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleAiInsight {
  const _VehicleAiInsight({
    required this.summary,
    required this.bullets,
  });

  final String summary;
  final List<String> bullets;
}

class _VehicleMaintenanceList extends StatelessWidget {
  const _VehicleMaintenanceList({
    required this.reminders,
  });

  final List<MaintenanceReminder> reminders;

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

