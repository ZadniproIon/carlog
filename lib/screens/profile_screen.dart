import 'package:flutter/material.dart';

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
  });

  final MockAuthUser user;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onLogout;
  final bool firebaseEnabled;
  final bool usingLocalData;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Account', icon: Icon(Icons.person_outline)),
              Tab(text: 'Preferences', icon: Icon(Icons.tune)),
              Tab(text: 'Developer', icon: Icon(Icons.developer_mode)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AccountTab(
              user: widget.user,
              firebaseEnabled: widget.firebaseEnabled,
              usingLocalData: widget.usingLocalData,
            ),
            const _PreferencesTabContainer(),
            const _DeveloperTabContainer(),
          ],
        ),
      ),
    );
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
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({
    required this.user,
    required this.firebaseEnabled,
    required this.usingLocalData,
  });

  final MockAuthUser user;
  final bool firebaseEnabled;
  final bool usingLocalData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    _avatarInitials(user.name),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            icon: user.isGuest
                                ? Icons.person_off_outlined
                                : Icons.verified_user_outlined,
                            label: user.isGuest ? 'Guest mode' : 'Signed in',
                          ),
                          _Badge(
                            icon: user.isCloudUser && !usingLocalData
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            label: user.isCloudUser && !usingLocalData
                                ? 'Firebase account'
                                : 'Local account',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Account status',
          child: Column(
            children: [
              const _RowLine(label: 'Plan', value: 'Demo'),
              _RowLine(
                label: 'Sync',
                value: user.isCloudUser && !usingLocalData
                    ? 'Firebase Cloud Firestore'
                    : 'Mock local mode',
              ),
              _RowLine(
                label: 'Security',
                value: user.isCloudUser
                    ? 'Firebase email/password'
                    : 'Password login (mock)',
              ),
              _RowLine(
                label: 'Data source',
                value: user.isCloudUser && !usingLocalData
                    ? 'Cloud account dataset'
                    : 'Preloaded mock dataset',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Connected services',
          child: Column(
            children: [
              _RowLine(
                label: 'Cloud backup',
                value: user.isCloudUser && !usingLocalData
                    ? 'Connected'
                    : firebaseEnabled
                    ? 'Available, using local fallback'
                    : 'Not configured',
              ),
              const _RowLine(
                label: 'Receipt OCR API',
                value: 'Demo integration',
              ),
              const _RowLine(
                label: 'Speech recognition',
                value: 'Demo integration',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _avatarInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class _PreferencesTabContainer extends StatefulWidget {
  const _PreferencesTabContainer();

  @override
  State<_PreferencesTabContainer> createState() =>
      _PreferencesTabContainerState();
}

class _PreferencesTabContainerState extends State<_PreferencesTabContainer> {
  bool _notificationsEnabled = true;
  bool _maintenanceRemindersEnabled = true;
  bool _privacyMode = false;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_ProfileScreenState>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _Section(
          title: 'Appearance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme mode', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                'Choose how CarLog follows device appearance.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ThemeMode>(
                initialValue: parent.widget.themeMode,
                decoration: const InputDecoration(
                  labelText: 'Mode',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    parent.widget.onThemeModeChanged(value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Notifications',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('General notifications'),
                subtitle: const Text('Expense and account alerts'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                secondary: const Icon(Icons.notifications_outlined),
              ),
              const Divider(height: 0),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maintenance reminders'),
                subtitle: const Text('ITP, oil, tires and inspections'),
                value: _maintenanceRemindersEnabled,
                onChanged: (value) {
                  setState(() => _maintenanceRemindersEnabled = value);
                },
                secondary: const Icon(Icons.build_circle_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Privacy',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Privacy mode'),
            subtitle: const Text('Hide sensitive values in screenshots'),
            value: _privacyMode,
            onChanged: (value) {
              setState(() => _privacyMode = value);
            },
            secondary: const Icon(Icons.privacy_tip_outlined),
          ),
        ),
      ],
    );
  }
}

class _DeveloperTabContainer extends StatefulWidget {
  const _DeveloperTabContainer();

  @override
  State<_DeveloperTabContainer> createState() => _DeveloperTabContainerState();
}

class _DeveloperTabContainerState extends State<_DeveloperTabContainer> {
  bool _developerLogsEnabled = false;
  bool _mockFailuresEnabled = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _Section(
          title: 'Testing actions',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Simulate notifications'),
                subtitle: const Text('Push 3 local demo notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  NotificationService.showDemoNotifications(context);
                },
              ),
              const Divider(height: 0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_arrow_outlined),
                title: const Text('Run UI health check'),
                subtitle: const Text('Show a mock system test result'),
                trailing: const Icon(Icons.chevron_right),
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Debug toggles',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable verbose logs'),
                subtitle: const Text('Developer-only local log mode'),
                value: _developerLogsEnabled,
                onChanged: (value) {
                  setState(() => _developerLogsEnabled = value);
                },
                secondary: const Icon(Icons.terminal_outlined),
              ),
              const Divider(height: 0),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Force mock API failures'),
                subtitle: const Text('Useful to test error states in demo'),
                value: _mockFailuresEnabled,
                onChanged: (value) {
                  setState(() => _mockFailuresEnabled = value);
                },
                secondary: const Icon(Icons.bug_report_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
