import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/spark_top_bar.dart';

import '../models.dart';
import '../widgets/demo_brand_logo.dart';
import '../widgets/category_chart.dart';
import '../widgets/expense_list_tile.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({
    super.key,
    required this.vehicles,
    required this.expenses,
    required this.reminders,
    required this.demoModeEnabled,
    required this.onAddVehicle,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onUpdateVehicleMileage,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final bool demoModeEnabled;
  final VoidCallback onAddVehicle;
  final ValueChanged<Vehicle> onEditVehicle;
  final ValueChanged<String> onDeleteVehicle;
  final ValueChanged<String> onAddReminder;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;
  final ValueChanged<Vehicle> onUpdateVehicleMileage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SparkTopBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            tooltip: 'Add vehicle',
            onPressed: onAddVehicle,
            icon: const Icon(LucideIcons.plus),
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
                          demoModeEnabled: demoModeEnabled,
                          onEditVehicle: onEditVehicle,
                          onDeleteVehicle: onDeleteVehicle,
                          onAddReminder: onAddReminder,
                          onEditReminder: onEditReminder,
                          onDeleteReminder: onDeleteReminder,
                          onEditExpense: onEditExpense,
                          onDeleteExpense: onDeleteExpense,
                          onUpdateVehicleMileage: onUpdateVehicleMileage,
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
                              DemoBrandLogo(
                                brand: vehicle.brand,
                                demoModeEnabled: demoModeEnabled,
                              ),
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
                                icon: LucideIcons.calendar,
                              ),
                              _InfoChip(
                                label: vehicle.engine,
                                icon: LucideIcons.gauge,
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

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    required this.expenses,
    required this.reminders,
    required this.demoModeEnabled,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onUpdateVehicleMileage,
  });

  final Vehicle vehicle;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final bool demoModeEnabled;
  final ValueChanged<Vehicle> onEditVehicle;
  final ValueChanged<String> onDeleteVehicle;
  final ValueChanged<String> onAddReminder;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;
  final ValueChanged<Vehicle> onUpdateVehicleMileage;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Vehicle _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleExpenses = widget.expenses
        .where((e) => e.vehicleId == _vehicle.id)
        .toList();
    final vehicleReminders =
        widget.reminders.where((r) => r.vehicleId == _vehicle.id).toList()
          ..sort((a, b) {
            final aDate = a.dueDate ?? DateTime(9999);
            final bDate = b.dueDate ?? DateTime(9999);
            return aDate.compareTo(bDate);
          });

    vehicleExpenses.sort((a, b) => b.date.compareTo(a.date));

    final categoryTotals = <ExpenseCategory, double>{};
    for (final e in vehicleExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: SparkTopBar(
        title: Text('${_vehicle.displayName} - ${_vehicle.year}'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Vehicle actions',
            onSelected: (value) {
              final navigator = Navigator.of(context);
              if (value == 'edit') {
                widget.onEditVehicle(_vehicle);
              } else if (value == 'update_mileage') {
                final rootContext = navigator.context;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleMileageUpdate(rootContext);
                });
              } else if (value == 'delete') {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final shouldDelete = await _confirmDelete(context);
                  if (!shouldDelete) {
                    return;
                  }
                  widget.onDeleteVehicle(_vehicle.id);
                  navigator.pop();
                });
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'update_mileage',
                child: Text('Update mileage'),
              ),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: const Icon(LucideIcons.moreVertical),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onAddReminder(_vehicle.id),
        icon: const Icon(LucideIcons.bellPlus),
        label: const Text('Add reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DemoBrandLogo(
                            brand: _vehicle.brand,
                            demoModeEnabled: widget.demoModeEnabled,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _vehicle.displayName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_vehicle.year} - ${_vehicle.engine}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                title: 'Specs',
                icon: LucideIcons.slidersHorizontal,
                child: Column(
                  children: [
                    _SpecRow(label: 'Year', value: '${_vehicle.year}'),
                    _SpecRow(label: 'Engine', value: _vehicle.engine),
                    _SpecRow(
                      label: 'Current mileage',
                      value: '${_vehicle.mileage} km',
                    ),
                    _SpecRow(label: 'VIN', value: _vehicle.vin),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryChart(
                categoryTotals: categoryTotals,
                expenseTimeline: vehicleExpenses,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Maintenance for this vehicle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (vehicleReminders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No maintenance reminders set.'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _VehicleMaintenanceList(
                  reminders: vehicleReminders,
                  onEditReminder: widget.onEditReminder,
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Expense history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (vehicleExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No expenses recorded for this vehicle yet.'),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < vehicleExpenses.length; i++) ...[
                    ExpenseListTile(
                      expense: vehicleExpenses[i],
                      vehicle: _vehicle,
                      flat: true,
                      onEdit: () => widget.onEditExpense(vehicleExpenses[i]),
                      onDelete: () =>
                          widget.onDeleteExpense(vehicleExpenses[i].id),
                    ),
                    if (i < vehicleExpenses.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete vehicle?'),
          content: const Text(
            'This removes the vehicle and all related expenses/reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<int?> _showUpdateMileageDialog(BuildContext context) async {
    int? draftMileage = _vehicle.mileage;
    String? errorText;
    int? result;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update mileage'),
              content: TextFormField(
                initialValue: _vehicle.mileage.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Mileage (km)',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  draftMileage = int.tryParse(value.trim());
                  if (errorText != null) {
                    setState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (draftMileage == null || draftMileage! <= 0) {
                      setState(() => errorText = 'Enter a valid mileage');
                      return;
                    }
                    result = draftMileage;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _handleMileageUpdate(BuildContext context) async {
    try {
      // Ensure popup-menu route is fully gone before opening dialog.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!context.mounted) {
        return;
      }

      final nextMileage = await _showUpdateMileageDialog(context);
      if (nextMileage == null || !context.mounted) {
        return;
      }

      final updatedVehicle = _vehicle.copyWith(mileage: nextMileage);
      setState(() {
        _vehicle = updatedVehicle;
      });
      widget.onUpdateVehicleMileage(updatedVehicle);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Mileage updated.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not update mileage. Please try again.')),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.icon,
    required this.child,
  });

  final String title;
  final IconData? icon;
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
                if (icon != null)
                  Icon(icon!),
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
  });

  final List<MaintenanceReminder> reminders;
  final ValueChanged<MaintenanceReminder> onEditReminder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final iconBackground = isDark
        ? const Color(0xFF4A3A2F)
        : const Color(0xFFFFE8D8);
    final iconForeground = isDark
        ? const Color(0xFFFFC79E)
        : const Color(0xFF8A4E1F);
    return Column(
      children: [
        for (var i = 0; i < reminders.length; i++) ...[
          Builder(
            builder: (context) {
              final reminder = reminders[i];
              final dueInfo = _buildDueInfo(reminder);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () => onEditReminder(reminder),
                  leading: CircleAvatar(
                    backgroundColor: iconBackground,
                    child: Icon(
                      LucideIcons.wrench,
                      color: iconForeground,
                    ),
                  ),
                  title: Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('$dueInfo\n${reminder.description}'),
                  isThreeLine: true,
                ),
              );
            },
          ),
          if (i < reminders.length - 1) const SizedBox(height: 10),
        ],
      ],
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
