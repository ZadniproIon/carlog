import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    required this.activeSharingRole,
    required this.activeSharingUserId,
    required this.sharedAccessByVehicleId,
    required this.onAddVehicle,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onUpdateVehicleMileage,
    required this.onManageSharing,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final bool demoModeEnabled;
  final DemoSharingRole activeSharingRole;
  final String activeSharingUserId;
  final Map<String, SharedVehicleAccess> sharedAccessByVehicleId;
  final VoidCallback onAddVehicle;
  final ValueChanged<Vehicle> onEditVehicle;
  final ValueChanged<String> onDeleteVehicle;
  final ValueChanged<String> onAddReminder;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;
  final ValueChanged<Vehicle> onUpdateVehicleMileage;
  final ValueChanged<String> onManageSharing;

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
                          activeSharingRole: activeSharingRole,
                          activeSharingUserId: activeSharingUserId,
                          sharedAccess: sharedAccessByVehicleId[vehicle.id],
                          onEditVehicle: onEditVehicle,
                          onDeleteVehicle: onDeleteVehicle,
                          onAddReminder: onAddReminder,
                          onEditReminder: onEditReminder,
                          onDeleteReminder: onDeleteReminder,
                          onEditExpense: onEditExpense,
                          onDeleteExpense: onDeleteExpense,
                          onUpdateVehicleMileage: onUpdateVehicleMileage,
                          onManageSharing: onManageSharing,
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
                                vehicle.displayLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Text(
                                '${vehicle.mileage} ${distanceUnitShortLabel(vehicle.distanceUnit)}',
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
                                label: '${vehicle.year}',
                                icon: LucideIcons.calendar,
                              ),
                              _InfoChip(
                                label: vehicle.engine,
                                icon: LucideIcons.gauge,
                              ),
                              _InfoChip(
                                label: vehicleFuelTypeLabel(vehicle.fuelType),
                                icon: LucideIcons.droplets,
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

class _SharedOwnerBanner extends StatelessWidget {
  const _SharedOwnerBanner({required this.access});

  final SharedVehicleAccess access;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.users, color: scheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This vehicle is shared with you by Stela Zadnipro (stela.zadnipro@gmail.com).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoVehicleOwnerBanner extends StatelessWidget {
  const _DemoVehicleOwnerBanner({
    required this.ownerName,
    required this.ownerEmail,
  });

  final String ownerName;
  final String ownerEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.userCheck, color: scheme.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This vehicle is owned by $ownerName ($ownerEmail).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
    required this.activeSharingRole,
    required this.activeSharingUserId,
    required this.sharedAccess,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAddReminder,
    required this.onEditReminder,
    required this.onDeleteReminder,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onUpdateVehicleMileage,
    required this.onManageSharing,
  });

  final Vehicle vehicle;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final bool demoModeEnabled;
  final DemoSharingRole activeSharingRole;
  final String activeSharingUserId;
  final SharedVehicleAccess? sharedAccess;
  final ValueChanged<Vehicle> onEditVehicle;
  final ValueChanged<String> onDeleteVehicle;
  final ValueChanged<String> onAddReminder;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final ValueChanged<String> onDeleteReminder;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;
  final ValueChanged<Vehicle> onUpdateVehicleMileage;
  final ValueChanged<String> onManageSharing;

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
    final canManageVehicle =
        widget.sharedAccess == null ||
        widget.sharedAccess!.isOwner(widget.activeSharingUserId);
    final showManageSharing =
        widget.demoModeEnabled &&
        widget.activeSharingRole == DemoSharingRole.owner &&
        canManageVehicle;
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
        title: Text('${_vehicle.displayLabel} - ${_vehicle.year}'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Vehicle actions',
            onSelected: (value) {
              final navigator = Navigator.of(context);
              if (value == 'sharing') {
                widget.onManageSharing(_vehicle.id);
              } else if (value == 'edit') {
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
            itemBuilder: (context) => [
              if (showManageSharing)
                const PopupMenuItem(
                  value: 'sharing',
                  child: Text('Manage sharing'),
                ),
              if (canManageVehicle)
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (canManageVehicle)
                const PopupMenuItem(
                  value: 'update_mileage',
                  child: Text('Update mileage'),
                ),
              if (canManageVehicle)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: const Icon(LucideIcons.moreVertical),
          ),
        ],
      ),
      floatingActionButton: canManageVehicle
          ? FloatingActionButton.extended(
              onPressed: () => widget.onAddReminder(_vehicle.id),
              icon: const Icon(LucideIcons.bellPlus),
              label: const Text('Add reminder'),
            )
          : null,
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
                              _vehicle.displayLabel,
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
                      if (_vehicle.specialTag.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _InfoChip(
                              label: _vehicle.specialTag,
                              icon: LucideIcons.tag,
                            ),
                          ],
                        ),
                      ],
                      if (_vehicle.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _vehicle.description.trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (widget.sharedAccess != null &&
                !widget.sharedAccess!.isOwner(widget.activeSharingUserId)) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SharedOwnerBanner(access: widget.sharedAccess!),
              ),
            ] else if (widget.demoModeEnabled &&
                _isDemoExternallyOwnedVehicle(_vehicle)) ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DemoVehicleOwnerBanner(
                  ownerName: 'Stela Zadnipro',
                  ownerEmail: 'stela.zadnipro@gmail.com',
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.demoModeEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _VehicleAiOverviewCard(
                  insight: _getVehicleAiInsight(_vehicle),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                title: 'Specs',
                icon: LucideIcons.slidersHorizontal,
                child: Column(
                  children: [
                    _SpecRow(label: 'Year', value: '${_vehicle.year}'),
                    _SpecRow(label: 'Engine name', value: _vehicle.engine),
                    if (_vehicle.specialTag.trim().isNotEmpty)
                      _SpecRow(label: 'Special tag', value: _vehicle.specialTag),
                    _SpecRow(
                      label: 'Fuel type',
                      value: vehicleFuelTypeLabel(_vehicle.fuelType),
                    ),
                    _SpecRow(
                      label: 'Current mileage',
                      value:
                          '${_vehicle.mileage} ${distanceUnitShortLabel(_vehicle.distanceUnit)}',
                    ),
                    _SpecRow(
                      label: 'Mileage unit',
                      value: distanceUnitLabel(_vehicle.distanceUnit),
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
                  distanceUnit: _vehicle.distanceUnit,
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
                  labelText:
                      'Mileage (${distanceUnitShortLabel(_vehicle.distanceUnit)})',
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
        const SnackBar(
          content: Text('Could not update mileage. Please try again.'),
        ),
      );
    }
  }

  _VehicleAiInsight _getVehicleAiInsight(Vehicle vehicle) {
    final key = '${vehicle.brand.toLowerCase()} ${vehicle.model.toLowerCase()}';

    if (key.contains('volkswagen') && key.contains('passat')) {
      return const _VehicleAiInsight(
        summary:
            'Volkswagen Passat 2018 is generally a reliable long-distance daily driver when maintenance is kept on schedule. It is comfortable, efficient, and usually predictable to own.',
        bullets: [
          'Watch for EGR, DPF, and turbo-related issues on higher-mileage diesel cars.',
          'DSG servicing and suspension bush wear are worth keeping an eye on.',
          'Strong as a daily and highway car, but delayed service can get expensive quickly.',
        ],
      );
    }

    if (key.contains('tesla') && key.contains('model 3')) {
      return const _VehicleAiInsight(
        summary:
            'Tesla Model 3 is efficient, quick, and relatively low-maintenance compared to combustion cars. Day-to-day ownership is usually simple if charging and tire care are handled well.',
        bullets: [
          'Watch for tire wear, alignment, and suspension wear on rough roads.',
          'Battery and drivetrain are usually strong, but smaller hardware items still matter.',
          'A very usable daily car, with costs driven more by tires and charging habits than service visits.',
        ],
      );
    }

    if (key.contains('porsche') && key.contains('cayenne')) {
      return const _VehicleAiInsight(
        summary:
            'Porsche Cayenne is a capable premium SUV with strong comfort and performance, but ownership costs are usually above average. It feels excellent when maintained properly.',
        bullets: [
          'Watch for air suspension wear, cooling system issues, and expensive brake or tire replacement costs.',
          'Hybrid-related checks and regular servicing matter more than on a typical family SUV.',
          'Very rewarding to own when maintained well, but deferred maintenance tends to stack up fast.',
        ],
      );
    }

    return const _VehicleAiInsight(
      summary:
          'This vehicle has a balanced ownership profile when maintained consistently. Preventive service and good records usually make the biggest difference.',
      bullets: [
        'Track recurring issues early instead of waiting for them to become patterns.',
        'Stay on top of service intervals and major consumables.',
        'Good maintenance history helps both reliability and resale value.',
      ],
    );
  }

  bool _isDemoExternallyOwnedVehicle(Vehicle vehicle) {
    return vehicle.brand.toLowerCase() == 'porsche' &&
        vehicle.model.toLowerCase() == 'cayenne';
  }
}

class _VehicleAiInsight {
  const _VehicleAiInsight({required this.summary, required this.bullets});

  final String summary;
  final List<String> bullets;
}

class JoinSharedVehicleScreen extends StatefulWidget {
  const JoinSharedVehicleScreen({super.key, required this.onSubmitCode});

  final Future<dynamic> Function(String code) onSubmitCode;

  @override
  State<JoinSharedVehicleScreen> createState() => _JoinSharedVehicleScreenState();
}

class _JoinSharedVehicleScreenState extends State<JoinSharedVehicleScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final result = await widget.onSubmitCode(_controller.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (result == null) {
      setState(() => _errorText = 'Could not join this vehicle.');
      return;
    }
    final success = result.success == true;
    if (success) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() {
      _errorText = (result.message as String?) ?? 'Could not join this vehicle.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SparkTopBar(title: Text('Join with code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a shared vehicle code',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the code provided by the vehicle owner to sync the car, expenses, and reminders into your account.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Shared code',
                  hintText: 'PASSAT-A1B2',
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _isLoading ? null : _submit(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleSharingManagementScreen extends StatefulWidget {
  const VehicleSharingManagementScreen({
    super.key,
    required this.vehicle,
    required this.access,
    required this.activeUserId,
    required this.memberLabels,
    required this.onRevokeAccess,
    required this.onTransferOwnership,
    required this.onRegenerateCode,
  });

  final Vehicle vehicle;
  final SharedVehicleAccess access;
  final String activeUserId;
  final Map<String, String> memberLabels;
  final Future<void> Function(String memberUserId) onRevokeAccess;
  final Future<void> Function() onTransferOwnership;
  final Future<String> Function() onRegenerateCode;

  @override
  State<VehicleSharingManagementScreen> createState() =>
      _VehicleSharingManagementScreenState();
}

class _VehicleSharingManagementScreenState
    extends State<VehicleSharingManagementScreen> {
  late SharedVehicleAccess _access;
  late List<String> _demoMemberIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _access = widget.access;
    _demoMemberIds = const [
      'share_member_stela',
      'share_member_mihai',
      'share_member_anatolie',
    ];
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
  }

  Future<void> _handleRevoke(String memberUserId) async {
    await _runBusy(() async {
      if (_access.memberUserIds.contains(memberUserId)) {
        await widget.onRevokeAccess(memberUserId);
        _access = _access.copyWith(
          memberUserIds: _access.memberUserIds
              .where((member) => member != memberUserId)
              .toList(),
        );
      }
      _demoMemberIds = _demoMemberIds
          .where((member) => member != memberUserId)
          .toList();
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access to this shared vehicle was removed.')),
    );
  }

  Future<void> _handleTransferOwnership() async {
    await _runBusy(() async {
      final nextOwnerId = _access.ownerUserId == 'demo_owner'
          ? 'demo_recipient'
          : 'demo_owner';
      await widget.onTransferOwnership();
      final nextMembers = <String>{'demo_owner', 'demo_recipient'}
        ..remove(nextOwnerId);
      _access = _access.copyWith(
        ownerUserId: nextOwnerId,
        ownerName: widget.memberLabels[nextOwnerId]?.split(' (').first ?? '',
        ownerEmail: _extractEmail(widget.memberLabels[nextOwnerId] ?? ''),
        memberUserIds: nextMembers.toList(),
      );
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle ownership transferred.')),
    );
  }

  Future<void> _handleRegenerateCode() async {
    await _runBusy(() async {
      final code = await widget.onRegenerateCode();
      _access = _access.copyWith(inviteCode: code);
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New shared code: ${_access.inviteCode}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberIds = _demoMemberIds;
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Scaffold(
      appBar: const SparkTopBar(title: Text('Manage sharing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current share code',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _access.inviteCode,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _access.inviteCode),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing code copied.'),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.copy),
                      label: const Text('Copy code'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _handleRegenerateCode,
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Regenerate code'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (memberIds.isEmpty)
                    const Text('No members have joined this shared vehicle yet.')
                  else
                    ...memberIds.map((memberId) {
                      final contact = _parseContact(
                        widget.memberLabels[memberId] ?? memberId,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    contact.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: muted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _handleRevoke(memberId),
                              child: const Text('Revoke access'),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _handleTransferOwnership,
              icon: const Icon(LucideIcons.repeat2),
              label: const Text('Transfer ownership'),
            ),
          ),
        ],
      ),
    );
  }

  String _extractEmail(String label) {
    return _parseContact(label).email;
  }

  _SharingContact _parseContact(String label) {
    if (label.contains('|')) {
      final parts = label.split('|');
      return _SharingContact(
        name: parts.first.trim(),
        email: parts.length > 1 ? parts[1].trim() : '',
      );
    }
    final match = RegExp(r'^(.*?)(?:\s*\(([^)]+)\))?$').firstMatch(label);
    return _SharingContact(
      name: match?.group(1)?.trim() ?? label,
      email: match?.group(2)?.trim() ?? '',
    );
  }
}

class _SharingContact {
  const _SharingContact({required this.name, required this.email});

  final String name;
  final String email;
}

class _VehicleAiOverviewCard extends StatelessWidget {
  const _VehicleAiOverviewCard({required this.insight});

  final _VehicleAiInsight insight;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFB8C00);

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
                const Icon(LucideIcons.sparkles, color: accent),
                const SizedBox(width: 8),
                Text(
                  'AI overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < insight.bullets.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(LucideIcons.sparkles, size: 12, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.bullets[i],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
              if (i < insight.bullets.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.icon, required this.child});

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
                if (icon != null) Icon(icon!),
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
    required this.distanceUnit,
    required this.onEditReminder,
  });

  final List<MaintenanceReminder> reminders;
  final DistanceUnit distanceUnit;
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
              final dueInfo = _buildDueInfo(reminder, distanceUnit);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () => onEditReminder(reminder),
                  leading: CircleAvatar(
                    backgroundColor: iconBackground,
                    child: Icon(LucideIcons.wrench, color: iconForeground),
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

  String _buildDueInfo(
    MaintenanceReminder reminder,
    DistanceUnit distanceUnit,
  ) {
    if (reminder.dueDate != null) {
      final date = reminder.dueDate!;
      return 'Due on ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    if (reminder.dueMileage != null) {
      return 'Due at ${reminder.dueMileage} ${distanceUnitShortLabel(distanceUnit)}';
    }
    return 'No due information';
  }
}
