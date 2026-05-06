import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/demo_brand_logo.dart';
import '../widgets/spark_top_bar.dart';

import '../models.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeMode,
    required this.expenseCurrency,
    required this.fuelPriceCountry,
    required this.onThemeModeChanged,
    required this.onExpenseCurrencyChanged,
    required this.onFuelPriceCountryChanged,
    required this.onLogout,
    required this.vehicles,
    required this.firebaseEnabled,
    required this.usingLocalData,
    required this.demoModeEnabled,
    required this.onDemoModeChanged,
    required this.showAnomalyDemoButtons,
    required this.onShowAnomalyDemoButtonsChanged,
    required this.fleetScreenshotDemoModeEnabled,
    required this.onFleetScreenshotDemoModeChanged,
    required this.presentationDemoModeEnabled,
    required this.onPresentationDemoModeChanged,
    required this.onResetPresentationDemo,
    required this.onRunPresentationDemoImport,
    required this.onUpdateProfile,
  });

  final MockAuthUser user;
  final ThemeMode themeMode;
  final ExpenseCurrency expenseCurrency;
  final FuelPriceCountry fuelPriceCountry;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<ExpenseCurrency> onExpenseCurrencyChanged;
  final ValueChanged<FuelPriceCountry> onFuelPriceCountryChanged;
  final VoidCallback onLogout;
  final List<Vehicle> vehicles;
  final bool firebaseEnabled;
  final bool usingLocalData;
  final bool demoModeEnabled;
  final ValueChanged<bool> onDemoModeChanged;
  final bool showAnomalyDemoButtons;
  final ValueChanged<bool> onShowAnomalyDemoButtonsChanged;
  final bool fleetScreenshotDemoModeEnabled;
  final ValueChanged<bool> onFleetScreenshotDemoModeChanged;
  final bool presentationDemoModeEnabled;
  final ValueChanged<bool> onPresentationDemoModeChanged;
  final Future<void> Function() onResetPresentationDemo;
  final Future<int> Function() onRunPresentationDemoImport;
  final Future<String?> Function(String name, String email) onUpdateProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _maintenanceRemindersEnabled = true;
  bool _developerLogsEnabled = false;
  bool _mockFailuresEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SparkTopBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const _SectionTitle('Account'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _MenuAccountSummary(
                title: widget.user.name,
                subtitle: _accountSubtitle(),
                initials: _avatarInitials(widget.user.name),
              ),
              _MenuItem(
                icon: LucideIcons.edit3,
                label: 'Edit profile fields',
                subtitle: 'Name and email',
                onTap: () => _showEditProfileDialog(context),
              ),
              _MenuItem(
                icon: LucideIcons.logOut,
                label: 'Sign out',
                isDestructive: true,
                onTap: _confirmLogout,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Preferences'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _ThemeModeItem(
                value: widget.themeMode,
                onChanged: widget.onThemeModeChanged,
              ),
              _CurrencyItem(
                value: widget.expenseCurrency,
                onChanged: widget.onExpenseCurrencyChanged,
              ),
              _FuelPriceCountryItem(
                value: widget.fuelPriceCountry,
                onChanged: widget.onFuelPriceCountryChanged,
              ),
              _MenuSwitchItem(
                icon: LucideIcons.wrench,
                label: 'Maintenance reminders',
                subtitle: 'ITP, oil, tires and inspections',
                value: _maintenanceRemindersEnabled,
                onChanged: (value) {
                  setState(() => _maintenanceRemindersEnabled = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Data'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _MenuItem(
                icon: LucideIcons.upload,
                label: 'Import data',
                subtitle: 'Import from files',
                onTap: _openImportDataFlow,
              ),
              _MenuItem(
                icon: LucideIcons.download,
                label: 'Export data',
                subtitle: 'Export vehicles, expenses and reminders',
                onTap: _openExportDataFlow,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Developer'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _MenuItem(
                icon: LucideIcons.bell,
                label: 'Simulate notifications',
                subtitle: 'Push 3 local demo notifications',
                onTap: () {
                  NotificationService.showDemoNotifications(context);
                },
              ),
              _MenuItem(
                icon: LucideIcons.play,
                label: 'Run UI health check',
                subtitle: 'Show a mock system test result',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'UI health check: all demo modules passed.',
                      ),
                    ),
                  );
                },
              ),
              _MenuSwitchItem(
                icon: LucideIcons.terminal,
                label: 'Enable verbose logs',
                subtitle: 'Developer-only local log mode',
                value: _developerLogsEnabled,
                onChanged: (value) {
                  setState(() => _developerLogsEnabled = value);
                },
              ),
              _MenuSwitchItem(
                icon: LucideIcons.bug,
                label: 'Force mock API failures',
                subtitle: 'Useful to test error states in demo',
                value: _mockFailuresEnabled,
                onChanged: (value) {
                  setState(() => _mockFailuresEnabled = value);
                },
              ),
              _MenuSwitchItem(
                icon: LucideIcons.alertTriangle,
                label: 'Show anomaly demo buttons',
                subtitle: 'Display anomaly detection triggers in Smart input',
                value: widget.showAnomalyDemoButtons,
                onChanged: widget.onShowAnomalyDemoButtonsChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Fleet demo'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _MenuSwitchItem(
                icon: LucideIcons.tags,
                label: 'Fleet screenshot mode',
                subtitle:
                    'Show similar Dacia vehicles with Moldovan plate tags.',
                value: widget.fleetScreenshotDemoModeEnabled,
                onChanged: widget.onFleetScreenshotDemoModeChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Presentation demo'),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _MenuSwitchItem(
                icon: LucideIcons.clapperboard,
                label: 'Presentation demo mode',
                subtitle: 'Use the staged 2-minute recording flow',
                value: widget.presentationDemoModeEnabled,
                onChanged: widget.onPresentationDemoModeChanged,
              ),
              _MenuItem(
                icon: LucideIcons.rotateCcw,
                label: 'Reset presentation demo',
                subtitle: 'Clear added data and restart the scripted flow',
                onTap: () => unawaited(widget.onResetPresentationDemo()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _accountSubtitle() {
    return widget.user.email;
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will return to the authentication screen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameController = TextEditingController(text: widget.user.name);
    final emailController = TextEditingController(text: widget.user.email);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit profile'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter a valid name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setState(() => isLoading = true);
                          final error = await widget.onUpdateProfile(
                            nameController.text.trim(),
                            emailController.text.trim(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          setState(() => isLoading = false);
                          if (error == null) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated.')),
                            );
                          } else {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _openImportDataFlow() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _ImportFlowScreen(
          presentationDemoModeEnabled: widget.presentationDemoModeEnabled,
          onRunPresentationDemoImport: widget.onRunPresentationDemoImport,
        ),
      ),
    );
  }

  Future<void> _openExportDataFlow() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _ExportFlowScreen(vehicles: widget.vehicles),
      ),
    );
  }
}

String _avatarInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuAccountSummary extends StatelessWidget {
  const _MenuAccountSummary({
    required this.title,
    required this.subtitle,
    required this.initials,
  });

  final String title;
  final String subtitle;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: textColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSwitchItem extends StatelessWidget {
  const _MenuSwitchItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ThemeModeItem extends StatelessWidget {
  const _ThemeModeItem({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(LucideIcons.palette, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme mode'),
                const SizedBox(height: 2),
                Text(
                  'Choose how CarLog follows device appearance.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<ThemeMode>(
              value: value,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (next) {
                if (next != null) {
                  onChanged(next);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyItem extends StatelessWidget {
  const _CurrencyItem({required this.value, required this.onChanged});

  final ExpenseCurrency value;
  final ValueChanged<ExpenseCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(LucideIcons.coins, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expense currency'),
                const SizedBox(height: 2),
                Text(
                  'Used by Add expense and default amounts.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<ExpenseCurrency>(
              value: value,
              items: ExpenseCurrency.values
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(expenseCurrencyCode(currency)),
                    ),
                  )
                  .toList(),
              onChanged: (next) {
                if (next != null) {
                  onChanged(next);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelPriceCountryItem extends StatelessWidget {
  const _FuelPriceCountryItem({required this.value, required this.onChanged});

  final FuelPriceCountry value;
  final ValueChanged<FuelPriceCountry> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(LucideIcons.globe, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fuel price country'),
                const SizedBox(height: 2),
                Text(
                  'Used for dashboard fuel trend and market prices.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<FuelPriceCountry>(
              value: value,
              items: FuelPriceCountry.values
                  .map(
                    (country) => DropdownMenuItem(
                      value: country,
                      child: Text(fuelPriceCountryLabel(country)),
                    ),
                  )
                  .toList(),
              onChanged: (next) {
                if (next != null) {
                  onChanged(next);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportFlowScreen extends StatefulWidget {
  const _ImportFlowScreen({
    required this.presentationDemoModeEnabled,
    required this.onRunPresentationDemoImport,
  });

  final bool presentationDemoModeEnabled;
  final Future<int> Function() onRunPresentationDemoImport;

  @override
  State<_ImportFlowScreen> createState() => _ImportFlowScreenState();
}

class _ExportFlowScreen extends StatefulWidget {
  const _ExportFlowScreen({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  State<_ExportFlowScreen> createState() => _ExportFlowScreenState();
}

class _ExportFlowScreenState extends State<_ExportFlowScreen> {
  bool _includeVehicles = true;
  bool _includeExpenses = true;
  bool _includeReminders = true;
  final Set<String> _vehicleIds = <String>{};
  final Set<ExpenseCategory> _categories = <ExpenseCategory>{};
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SparkTopBar(title: Text('Export data')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Text(
                    'Choose what you want to export.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a backup of your vehicles, expenses and reminders in a shareable file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('What to export'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    children: [
                      _ExportToggleRow(
                        icon: LucideIcons.car,
                        label: 'Vehicles',
                        subtitle: 'Vehicle records and details',
                        value: _includeVehicles,
                        onChanged: (value) {
                          setState(() {
                            _includeVehicles = value;
                          });
                        },
                      ),
                      _ExportToggleRow(
                        icon: LucideIcons.receipt,
                        label: 'Expenses',
                        subtitle: 'Expense history and categories',
                        value: _includeExpenses,
                        onChanged: (value) {
                          setState(() {
                            _includeExpenses = value;
                          });
                        },
                      ),
                      _ExportToggleRow(
                        icon: LucideIcons.calendarClock,
                        label: 'Reminders',
                        subtitle: 'Upcoming and completed reminders',
                        value: _includeReminders,
                        onChanged: (value) {
                          setState(() {
                            _includeReminders = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Filters'),
                  const SizedBox(height: 8),
                  Text('Vehicles', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.vehicles.map((vehicle) {
                      final selected = _vehicleIds.contains(vehicle.id);
                      return FilterChip(
                        selected: selected,
                        label: Text(vehicle.displayLabel),
                        avatar: DemoBrandLogo(
                          brand: vehicle.brand,
                          demoModeEnabled: true,
                          size: 16,
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _vehicleIds.add(vehicle.id);
                            } else {
                              _vehicleIds.remove(vehicle.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: _includeExpenses ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !_includeExpenses,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense categories',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ExpenseCategory.values.map((category) {
                              final selected = _categories.contains(category);
                              return FilterChip(
                                selected: selected,
                                label: Text(expenseCategoryLabel(category)),
                                avatar: Icon(
                                  expenseCategoryIcon(category),
                                  size: 16,
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _categories.add(category);
                                    } else {
                                      _categories.remove(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Date range',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(LucideIcons.calendar, size: 16),
                          label: Text(
                            _startDate == null
                                ? 'Start date'
                                : _formatDate(_startDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEndDate,
                          icon: const Icon(LucideIcons.calendar, size: 16),
                          label: Text(
                            _endDate == null
                                ? 'End date'
                                : _formatDate(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Last 30 days'),
                        onPressed: () => _setLastDays(30),
                      ),
                      ActionChip(
                        label: const Text('Last 90 days'),
                        onPressed: () => _setLastDays(90),
                      ),
                      ActionChip(
                        label: const Text('This year'),
                        onPressed: _setThisYear,
                      ),
                      ActionChip(
                        label: const Text('All time'),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset filters'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _hasSelectedExportType ? _startExport : null,
                  child: const Text('Export data'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasSelectedExportType =>
      _includeVehicles || _includeExpenses || _includeReminders;

  void _startExport() {
    final parts = <String>[];
    if (_vehicleIds.isNotEmpty) {
      parts.add(
        _vehicleIds.length == 1 ? '1 vehicle selected' : '${_vehicleIds.length} vehicles selected',
      );
    }
    if (_includeExpenses && _categories.isNotEmpty) {
      parts.add(
        _categories.length == 1
            ? '${expenseCategoryLabel(_categories.first)} category'
            : '${_categories.length} categories',
      );
    }
    if (_startDate != null || _endDate != null) {
      final from = _startDate == null ? 'Any' : _formatDate(_startDate!);
      final to = _endDate == null ? 'Any' : _formatDate(_endDate!);
      parts.add('$from - $to');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parts.isEmpty
              ? 'Export started. Your file will be ready shortly.'
              : 'Export started for ${parts.join(' • ')}.',
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _vehicleIds.clear();
      _categories.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      if (_startDate != null && _startDate!.isAfter(picked)) {
        _startDate = picked;
      }
    });
  }

  void _setLastDays(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = _endDate!.subtract(Duration(days: days - 1));
    });
  }

  void _setThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}


class _ExportToggleRow extends StatelessWidget {
  const _ExportToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}


class _ImportFlowScreenState extends State<_ImportFlowScreen> {
  int _stepIndex = 0;
  bool _vehiclePrepared = false;
  bool _isImporting = false;
  bool _importComplete = false;
  int? _importedEntriesCount;
  final List<_ImportFile> _selectedFiles = <_ImportFile>[];
  final TextEditingController _inputDataController = TextEditingController();

  @override
  void dispose() {
    _inputDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SparkTopBar(title: Text('Import data')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              _ImportStepHeader(stepIndex: _stepIndex),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 10),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_stepIndex == 0) {
      return _ImportPrerequisiteStep(
        isChecked: _vehiclePrepared,
        onChanged: (value) => setState(() => _vehiclePrepared = value),
      );
    }

    if (_stepIndex == 1) {
      return _ImportUploadStep(
        files: _selectedFiles,
        inputDataController: _inputDataController,
        onPickFiles: _pickFiles,
        onClearFiles: _clearFiles,
        onRemoveFileAt: _removeFileAt,
      );
    }

    return _ImportReviewStep(
      files: _selectedFiles,
      isImporting: _isImporting,
      isComplete: _importComplete,
      importedEntriesCount: _importedEntriesCount,
    );
  }

  Widget _buildBottomActions() {
    if (_stepIndex == 0) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _vehiclePrepared
              ? () => setState(() => _stepIndex = 1)
              : null,
          child: const Text('Continue'),
        ),
      );
    }

    if (_stepIndex == 1) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _stepIndex = 0),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _selectedFiles.isEmpty
                  ? null
                  : () => setState(() => _stepIndex = 2),
              child: const Text('Review'),
            ),
          ),
        ],
      );
    }

    if (_importComplete) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isImporting
                ? null
                : () => setState(() => _stepIndex = 1),
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isImporting ? null : _runImport,
            icon: _isImporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.play),
            label: Text(_isImporting ? 'Running...' : 'Start import'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'csv',
        'xlsx',
        'xls',
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'heic',
        'txt',
        'zip',
      ],
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final existingKeys = _selectedFiles.map((file) => file.key).toSet();
    final filesToAdd = <_ImportFile>[];
    for (final platformFile in result.files) {
      final file = _ImportFile.fromPlatformFile(platformFile);
      if (existingKeys.add(file.key)) {
        filesToAdd.add(file);
      }
    }

    if (filesToAdd.isEmpty) {
      return;
    }

    setState(() {
      _selectedFiles.addAll(filesToAdd);
      _importComplete = false;
      _importedEntriesCount = null;
    });
  }

  void _clearFiles() {
    setState(() {
      _selectedFiles.clear();
      _importComplete = false;
      _importedEntriesCount = null;
    });
  }

  void _removeFileAt(int index) {
    if (index < 0 || index >= _selectedFiles.length) {
      return;
    }

    setState(() {
      _selectedFiles.removeAt(index);
      _importComplete = false;
      _importedEntriesCount = null;
    });
  }

  Future<void> _runImport() async {
    setState(() {
      _isImporting = true;
      _importComplete = false;
      _importedEntriesCount = null;
    });

    int? importedEntriesCount;
    if (widget.presentationDemoModeEnabled) {
      importedEntriesCount = await widget.onRunPresentationDemoImport();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    if (!mounted) return;

    setState(() {
      _isImporting = false;
      _importComplete = true;
      _importedEntriesCount = importedEntriesCount;
    });
  }
}

class _ImportStepHeader extends StatelessWidget {
  const _ImportStepHeader({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.primary;
    final inactive = Theme.of(context).dividerColor;

    return Row(
      children: List<Widget>.generate(3, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: index <= stepIndex ? active : inactive,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _ImportPrerequisiteStep extends StatelessWidget {
  const _ImportPrerequisiteStep({
    required this.isChecked,
    required this.onChanged,
  });

  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey<String>('import_step_0'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.car, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                'Before you proceed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'First create the vehicle in the app. After that, upload the '
            'necessary files for this vehicle.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Many file formats are accepted.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: isChecked,
            onChanged: (value) => onChanged(value ?? false),
            title: const Text('I already created the vehicle in CarLog'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ImportUploadStep extends StatelessWidget {
  const _ImportUploadStep({
    required this.files,
    required this.inputDataController,
    required this.onPickFiles,
    required this.onClearFiles,
    required this.onRemoveFileAt,
  });

  final List<_ImportFile> files;
  final TextEditingController inputDataController;
  final Future<void> Function() onPickFiles;
  final VoidCallback onClearFiles;
  final ValueChanged<int> onRemoveFileAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey<String>('import_step_1'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload files', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Accepted formats: CSV, XLSX, XLS, PDF, JPG, JPEG, PNG, HEIC, TXT, ZIP and more.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: inputDataController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Input more context (optional)',
              hintText:
                  'Add context to help the system understand the files, for example: service history export, fuel receipts, insurance documents, prioritize mileage and reminders.',
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.fileUp, color: scheme.primary),
                const SizedBox(height: 8),
                const Text('Choose one or more files to import'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await onPickFiles();
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Choose files'),
                    ),
                    OutlinedButton(
                      onPressed: files.isEmpty ? null : onClearFiles,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: files.isEmpty
                ? Center(
                    child: Text(
                      'No files selected yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${file.format} - ${file.sizeLabel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Remove file',
                              onPressed: () => onRemoveFileAt(index),
                              icon: const Icon(LucideIcons.trash2, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ImportReviewStep extends StatelessWidget {
  const _ImportReviewStep({
    required this.files,
    required this.isImporting,
    required this.isComplete,
    required this.importedEntriesCount,
  });

  final List<_ImportFile> files;
  final bool isImporting;
  final bool isComplete;
  final int? importedEntriesCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey<String>('import_step_2'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review import', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            'Vehicle prerequisite completed. Files ready: ${files.length}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'The selected files are ready for import.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (isImporting) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 10),
            const Text('Processing files...'),
          ] else if (isComplete) ...[
            Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    importedEntriesCount == null
                        ? 'Import flow complete.'
                        : 'Import complete, added $importedEntriesCount entries',
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Press "Start import" to continue.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportFile {
  const _ImportFile({
    required this.name,
    required this.format,
    required this.sizeLabel,
    required this.rawSize,
  });

  factory _ImportFile.fromPlatformFile(PlatformFile file) {
    final extension = file.extension?.trim().toUpperCase();
    return _ImportFile(
      name: file.name,
      format: extension == null || extension.isEmpty ? 'FILE' : extension,
      sizeLabel: _formatFileSize(file.size),
      rawSize: file.size,
    );
  }

  final String name;
  final String format;
  final String sizeLabel;
  final int rawSize;

  String get key => '$name:$rawSize';
}

String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var index = 0;

  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }

  final decimals = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return '${value.toStringAsFixed(decimals)} ${units[index]}';
}
