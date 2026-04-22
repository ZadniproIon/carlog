import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/spark_top_bar.dart';

import '../models.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLogout,
    required this.firebaseEnabled,
    required this.usingLocalData,
    required this.demoModeEnabled,
    required this.onDemoModeChanged,
    required this.onUpdateProfile,
  });

  final MockAuthUser user;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onLogout;
  final bool firebaseEnabled;
  final bool usingLocalData;
  final bool demoModeEnabled;
  final ValueChanged<bool> onDemoModeChanged;
  final Future<String?> Function(String name, String email) onUpdateProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _maintenanceRemindersEnabled = true;
  bool _privacyMode = false;
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
              _MenuSwitchItem(
                icon: LucideIcons.flaskConical,
                label: 'Demo mode',
                subtitle: 'Use mock dataset instead of cloud data',
                value: widget.demoModeEnabled,
                onChanged: widget.onDemoModeChanged,
              ),
              _MenuSwitchItem(
                icon: LucideIcons.bell,
                label: 'General notifications',
                subtitle: 'Expense and account alerts',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
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
              _MenuSwitchItem(
                icon: LucideIcons.shield,
                label: 'Privacy mode',
                subtitle: 'Hide sensitive values in screenshots',
                value: _privacyMode,
                onChanged: (value) {
                  setState(() => _privacyMode = value);
                },
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
            ],
          ),
        ],
      ),
    );
  }

  String _accountSubtitle() {
    final sync = widget.user.isCloudUser && !widget.usingLocalData
        ? 'Firebase'
        : 'Local';
    final mode = widget.demoModeEnabled ? 'Demo data' : 'Live data';
    return '${widget.user.email}  |  $sync  |  $mode';
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
