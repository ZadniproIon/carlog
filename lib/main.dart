import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'mock_data.dart';
import 'models.dart';
import 'screens/add_expense_screen.dart';
import 'screens/add_reminder_screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/vehicles_screen.dart';
import 'services/carlog_repository.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  final firebaseEnabled = await _initializeFirebaseSafely();
  runApp(MyApp(firebaseEnabled: firebaseEnabled));
}

Future<bool> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (primaryError) {
    // Secondary fallback keeps local/mock mode usable on unsupported setups.
    try {
      await Firebase.initializeApp();
      return true;
    } catch (fallbackError) {
      debugPrint(
        'Firebase not configured yet, using mock mode: '
        '$primaryError | $fallbackError',
      );
      return false;
    }
  }
}

class _StoredAccount {
  const _StoredAccount({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.firebaseEnabled = false});

  final bool firebaseEnabled;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  MockAuthUser? _currentUser;
  late final CarlogRepository _repository;

  final Map<String, _StoredAccount> _accounts = {
    'driver@carlog.app': const _StoredAccount(
      name: 'Demo Driver',
      email: 'driver@carlog.app',
      password: 'demo1234',
    ),
  };

  @override
  void initState() {
    super.initState();

    _repository = CarlogRepository(
      firestore: widget.firebaseEnabled ? FirebaseFirestore.instance : null,
    );

    if (widget.firebaseEnabled) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUser = _mapFirebaseUser(firebaseUser);
      }
    }
  }

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  Future<String?> _updateProfile(String name, String email) async {
    final user = _currentUser;
    if (user == null) {
      return 'No active user session.';
    }

    if (user.isGuest) {
      setState(() {
        _currentUser = user.copyWith(name: name, email: email);
      });
      return null;
    }

    if (widget.firebaseEnabled) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return 'No Firebase session found.';
      }

      try {
        if (firebaseUser.displayName != name) {
          await firebaseUser.updateDisplayName(name);
        }
        if ((firebaseUser.email ?? '').toLowerCase() != email.toLowerCase()) {
          await firebaseUser.verifyBeforeUpdateEmail(email);
        }
        await _repository.updateProfile(user: user, name: name, email: email);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'requires-recent-login') {
          return 'Re-login required to change email.';
        }
        return error.message ?? 'Failed to update profile.';
      } catch (_) {
        return 'Failed to update profile.';
      }
    }

    setState(() {
      _currentUser = user.copyWith(name: name, email: email);
    });
    return null;
  }

  Future<String?> _handleLogin(String email, String password) async {
    if (widget.firebaseEnabled) {
      try {
        final credentials = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        final user = credentials.user;
        if (user == null) {
          return 'Could not sign in right now.';
        }

        if (!mounted) {
          return null;
        }

        setState(() {
          _currentUser = _mapFirebaseUser(user, fallbackEmail: email);
        });

        return null;
      } on FirebaseAuthException catch (error) {
        return _firebaseAuthError(error);
      } catch (_) {
        return 'Could not sign in right now.';
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final key = email.toLowerCase();
    final account = _accounts[key];
    if (account == null || account.password != password) {
      return 'Invalid email or password.';
    }

    setState(() {
      _currentUser = MockAuthUser(name: account.name, email: account.email);
    });

    return null;
  }

  Future<String?> _handleSignUp(
    String name,
    String email,
    String password,
  ) async {
    if (widget.firebaseEnabled) {
      try {
        final credentials = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = credentials.user;
        if (user == null) {
          return 'Could not create account right now.';
        }

        if (name.trim().isNotEmpty) {
          await user.updateDisplayName(name.trim());
        }
        await user.reload();

        final refreshedUser = FirebaseAuth.instance.currentUser ?? user;

        if (!mounted) {
          return null;
        }

        setState(() {
          _currentUser = _mapFirebaseUser(refreshedUser, fallbackEmail: email);
        });

        return null;
      } on FirebaseAuthException catch (error) {
        return _firebaseAuthError(error);
      } catch (_) {
        return 'Could not create account right now.';
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final key = email.toLowerCase();
    if (_accounts.containsKey(key)) {
      return 'An account with this email already exists.';
    }

    _accounts[key] = _StoredAccount(
      name: name,
      email: email,
      password: password,
    );

    setState(() {
      _currentUser = MockAuthUser(name: name, email: email);
    });

    return null;
  }

  Future<String?> _handleGoogleSignIn() async {
    if (!widget.firebaseEnabled) {
      return 'Google sign-in is not available in local mock mode.';
    }

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return 'Google sign-in was cancelled.';
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        return 'Could not sign in with Google right now.';
      }

      if (!mounted) {
        return null;
      }

      setState(() {
        _currentUser = _mapFirebaseUser(user);
      });
      return null;
    } on FirebaseAuthException catch (error) {
      return _firebaseAuthError(error);
    } catch (_) {
      return 'Google sign-in failed. Check Firebase Google provider setup.';
    }
  }

  void _enterGuestMode() {
    setState(() {
      _currentUser = MockAuthUser.guest();
    });
  }

  void _logout() {
    unawaited(_performLogout());
  }

  Future<void> _performLogout() async {
    final previousUser = _currentUser;

    if (widget.firebaseEnabled &&
        previousUser != null &&
        !previousUser.isGuest) {
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (_) {
        // Sign out failure should not block local app logout.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = null;
    });
  }

  MockAuthUser _mapFirebaseUser(User user, {String? fallbackEmail}) {
    final resolvedEmail = user.email ?? fallbackEmail ?? 'driver@carlog.app';
    final rawName = user.displayName?.trim() ?? '';

    return MockAuthUser(
      name: rawName.isNotEmpty ? rawName : _nameFromEmail(resolvedEmail),
      email: resolvedEmail,
      uid: user.uid,
      isCloudUser: true,
    );
  }

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    if (localPart.trim().isEmpty) {
      return 'Driver';
    }

    final words = localPart
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .toList();

    if (words.isEmpty) {
      return 'Driver';
    }

    return words.join(' ');
  }

  String _firebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please use a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Use a stronger password (at least 6 characters).';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'account-exists-with-different-credential':
        return 'This email already uses another sign-in method.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return error.message ?? 'Authentication failed. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF42A5F5),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'CarLog',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: lightScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: lightScheme.primaryContainer,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: darkScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: darkScheme.primaryContainer,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: _currentUser == null
          ? AuthScreen(
              onLogin: _handleLogin,
              onSignUp: _handleSignUp,
              onGoogleSignIn: _handleGoogleSignIn,
              onEnterGuest: _enterGuestMode,
              firebaseEnabled: widget.firebaseEnabled,
            )
          : HomeShell(
              key: ValueKey<String>(_currentUser!.email),
              themeMode: _themeMode,
              onThemeModeChanged: _onThemeModeChanged,
              currentUser: _currentUser!,
              onLogout: _logout,
              repository: _repository,
              firebaseEnabled: widget.firebaseEnabled,
              onUpdateProfile: _updateProfile,
            ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.currentUser,
    required this.onLogout,
    required this.repository,
    required this.firebaseEnabled,
    required this.onUpdateProfile,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final MockAuthUser currentUser;
  final VoidCallback onLogout;
  final CarlogRepository repository;
  final bool firebaseEnabled;
  final Future<String?> Function(String name, String email) onUpdateProfile;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const String _demoModePrefKey = 'demo_mode_enabled';

  int _selectedIndex = 0;
  late List<Vehicle> _vehicles;
  late List<CarExpense> _expenses;
  late List<MaintenanceReminder> _reminders;
  bool _usingLocalData = true;
  bool _demoModeEnabled = false;
  SharedPreferences? _preferences;
  CarlogDataSnapshot? _cachedNonDemoSnapshot;

  @override
  void initState() {
    super.initState();

    _vehicles = const [];
    _expenses = const [];
    _reminders = const [];

    unawaited(_loadPreferencesAndData());
  }

  Future<void> _loadPreferencesAndData() async {
    _preferences = await SharedPreferences.getInstance();
    final demoEnabled = _preferences!.getBool(_demoModePrefKey) ?? false;
    if (!mounted) {
      return;
    }
    _demoModeEnabled = demoEnabled;
    await _loadInitialData();
  }

  Future<void> _loadInitialData({bool forceRefresh = false}) async {
    if (_demoModeEnabled) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vehicles = List<Vehicle>.from(mockVehicles);
        _expenses = List<CarExpense>.from(mockExpenses)
          ..sort((a, b) => b.date.compareTo(a.date));
        _reminders = List<MaintenanceReminder>.from(mockReminders);
        _usingLocalData = true;
      });
      return;
    }

    if (!forceRefresh && _cachedNonDemoSnapshot != null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vehicles = List<Vehicle>.from(_cachedNonDemoSnapshot!.vehicles);
        _expenses = List<CarExpense>.from(_cachedNonDemoSnapshot!.expenses);
        _reminders = List<MaintenanceReminder>.from(
          _cachedNonDemoSnapshot!.reminders,
        );
        _usingLocalData = _cachedNonDemoSnapshot!.isLocalOnly;
      });
      return;
    }

    final snapshot = await widget.repository.loadInitialData(
      user: widget.currentUser,
    );

    if (!mounted) {
      return;
    }

    _cachedNonDemoSnapshot = snapshot;
    setState(() {
      _vehicles = snapshot.vehicles;
      _expenses = snapshot.expenses;
      _reminders = snapshot.reminders;
      _usingLocalData = snapshot.isLocalOnly;
    });
  }

  void _addExpense(CarExpense expense) {
    Vehicle? updatedVehicle;
    setState(() {
      _expenses.insert(0, expense);
      updatedVehicle = _applyVehicleMileageFromExpense(expense);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncExpense(expense));
      if (updatedVehicle != null) {
        unawaited(_syncVehicle(updatedVehicle!));
      }
    }
  }

  void _updateExpense(CarExpense expense) {
    Vehicle? updatedVehicle;
    setState(() {
      final index = _expenses.indexWhere((item) => item.id == expense.id);
      if (index == -1) {
        _expenses.insert(0, expense);
      } else {
        _expenses[index] = expense;
      }
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      updatedVehicle = _applyVehicleMileageFromExpense(expense);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncExpense(expense));
      if (updatedVehicle != null) {
        unawaited(_syncVehicle(updatedVehicle!));
      }
    }
  }

  void _deleteExpense(String expenseId) {
    setState(() {
      _expenses.removeWhere((item) => item.id == expenseId);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncDeleteExpense(expenseId));
    }
  }

  void _bulkDeleteExpenses(List<String> expenseIds) {
    final ids = expenseIds.toSet();
    setState(() {
      _expenses.removeWhere((item) => ids.contains(item.id));
    });

    if (!_demoModeEnabled) {
      for (final expenseId in ids) {
        unawaited(_syncDeleteExpense(expenseId));
      }
    }
  }

  Future<void> _syncExpense(CarExpense expense) async {
    try {
      await widget.repository.addExpense(
        user: widget.currentUser,
        expense: expense,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _usingLocalData = _demoModeEnabled || !widget.currentUser.isCloudUser;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expense saved locally. Cloud sync is currently unavailable.',
          ),
        ),
      );
      setState(() {
        _usingLocalData = true;
      });
    }
  }

  Future<void> _syncDeleteExpense(String expenseId) async {
    try {
      await widget.repository.deleteExpense(
        user: widget.currentUser,
        expenseId: expenseId,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete expense in cloud.')),
      );
      setState(() => _usingLocalData = true);
    }
  }

  Vehicle? _applyVehicleMileageFromExpense(CarExpense expense) {
    final vehicleIndex = _vehicles.indexWhere(
      (vehicle) => vehicle.id == expense.vehicleId,
    );
    if (vehicleIndex == -1) {
      return null;
    }

    final existingVehicle = _vehicles[vehicleIndex];
    if (expense.mileage <= existingVehicle.mileage) {
      return null;
    }

    final updatedVehicle = existingVehicle.copyWith(mileage: expense.mileage);
    _vehicles[vehicleIndex] = updatedVehicle;
    return updatedVehicle;
  }

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _vehicles.add(vehicle);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncVehicle(vehicle));
    }
  }

  void _updateVehicle(Vehicle vehicle) {
    setState(() {
      final index = _vehicles.indexWhere((item) => item.id == vehicle.id);
      if (index == -1) {
        _vehicles.add(vehicle);
      } else {
        _vehicles[index] = vehicle;
      }
    });

    if (!_demoModeEnabled) {
      unawaited(_syncVehicle(vehicle));
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    final shouldDelete = await showDialog<bool>(
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

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      _expenses.removeWhere((expense) => expense.vehicleId == vehicleId);
      _reminders.removeWhere((reminder) => reminder.vehicleId == vehicleId);
    });

    if (!_demoModeEnabled) {
      try {
        await widget.repository.deleteVehicle(
          user: widget.currentUser,
          vehicleId: vehicleId,
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete vehicle in cloud.')),
        );
        setState(() => _usingLocalData = true);
      }
    }
  }

  Future<void> _syncVehicle(Vehicle vehicle) async {
    try {
      await widget.repository.addVehicle(
        user: widget.currentUser,
        vehicle: vehicle,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _usingLocalData = _demoModeEnabled || !widget.currentUser.isCloudUser;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle saved locally. Cloud sync is currently unavailable.',
          ),
        ),
      );
      setState(() {
        _usingLocalData = true;
      });
    }
  }

  Future<void> _openAddVehicleFlow() async {
    final newVehicle = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    );
    if (newVehicle != null) {
      _addVehicle(newVehicle);
    }
  }

  Future<void> _openEditVehicleFlow(Vehicle vehicle) async {
    final updatedVehicle = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(initialVehicle: vehicle),
      ),
    );
    if (updatedVehicle != null) {
      _updateVehicle(updatedVehicle);
    }
  }

  Future<void> _openEditExpenseFlow(CarExpense expense) async {
    final updatedExpense = await Navigator.of(context).push<CarExpense>(
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          vehicles: _vehicles,
          initialMode: ExpenseInputMode.manual,
          initialExpense: expense,
        ),
      ),
    );
    if (updatedExpense != null) {
      _updateExpense(updatedExpense);
    }
  }

  Future<void> _openAddReminderFlow(String vehicleId) async {
    final reminder = await Navigator.of(context).push<MaintenanceReminder>(
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(vehicleId: vehicleId),
      ),
    );
    if (reminder != null) {
      _upsertReminder(reminder);
    }
  }

  Future<void> _openEditReminderFlow(MaintenanceReminder reminder) async {
    final updatedReminder = await Navigator.of(context)
        .push<MaintenanceReminder>(
          MaterialPageRoute(
            builder: (context) => AddReminderScreen(
              vehicleId: reminder.vehicleId,
              initialReminder: reminder,
            ),
          ),
        );
    if (updatedReminder != null) {
      _upsertReminder(updatedReminder);
    }
  }

  void _upsertReminder(MaintenanceReminder reminder) {
    setState(() {
      final index = _reminders.indexWhere((item) => item.id == reminder.id);
      if (index == -1) {
        _reminders.add(reminder);
      } else {
        _reminders[index] = reminder;
      }
    });

    if (!_demoModeEnabled) {
      unawaited(_syncReminder(reminder));
    }
  }

  void _deleteReminder(String reminderId) {
    setState(() {
      _reminders.removeWhere((item) => item.id == reminderId);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncDeleteReminder(reminderId));
    }
  }

  Future<void> _syncReminder(MaintenanceReminder reminder) async {
    try {
      await widget.repository.upsertReminder(
        user: widget.currentUser,
        reminder: reminder,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sync reminder in cloud.')),
      );
      setState(() => _usingLocalData = true);
    }
  }

  Future<void> _syncDeleteReminder(String reminderId) async {
    try {
      await widget.repository.deleteReminder(
        user: widget.currentUser,
        reminderId: reminderId,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete reminder in cloud.')),
      );
      setState(() => _usingLocalData = true);
    }
  }

  Future<void> _onDemoModeChanged(bool enabled) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    _preferences = prefs;
    unawaited(prefs.setBool(_demoModePrefKey, enabled));

    if (!mounted) {
      return;
    }

    setState(() {
      _demoModeEnabled = enabled;
    });

    if (enabled) {
      // Instant switch to demo data without waiting on any I/O.
      await _loadInitialData();
      return;
    }

    // Instant restore from cache if available.
    await _loadInitialData();
    // Background refresh to get latest cloud data.
    unawaited(_loadInitialData(forceRefresh: true));
  }

  Future<ExpenseInputMode?> _showExpenseInputModeSheet() {
    const modes = <ExpenseInputMode>[
      ExpenseInputMode.voice,
      ExpenseInputMode.text,
      ExpenseInputMode.manual,
    ];

    String modeTitle(ExpenseInputMode mode) {
      switch (mode) {
        case ExpenseInputMode.voice:
          return 'Voice';
        case ExpenseInputMode.text:
          return 'Text';
        case ExpenseInputMode.manual:
          return 'Manual';
      }
    }

    String modeSubtitle(ExpenseInputMode mode) {
      switch (mode) {
        case ExpenseInputMode.voice:
          return 'Dictate details, then review the form.';
        case ExpenseInputMode.text:
          return 'Type details, then review the form.';
        case ExpenseInputMode.manual:
          return 'Fill the form directly.';
      }
    }

    IconData modeIcon(ExpenseInputMode mode) {
      switch (mode) {
        case ExpenseInputMode.voice:
          return Icons.mic;
        case ExpenseInputMode.text:
          return Icons.text_fields;
        case ExpenseInputMode.manual:
          return Icons.edit_note;
      }
    }

    return showModalBottomSheet<ExpenseInputMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose input method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select one option to continue.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...modes.map((mode) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      leading: Icon(modeIcon(mode)),
                      title: Text(modeTitle(mode)),
                      subtitle: Text(modeSubtitle(mode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pop(mode),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        vehicles: _vehicles,
        expenses: _expenses,
        reminders: _reminders,
      ),
      ExpensesScreen(
        expenses: _expenses,
        vehicles: _vehicles,
        onEditExpense: _openEditExpenseFlow,
        onDeleteExpense: _deleteExpense,
        onBulkDeleteExpenses: _bulkDeleteExpenses,
      ),
      VehiclesScreen(
        vehicles: _vehicles,
        expenses: _expenses,
        reminders: _reminders,
        onAddVehicle: _openAddVehicleFlow,
        onEditVehicle: _openEditVehicleFlow,
        onDeleteVehicle: (vehicleId) => unawaited(_deleteVehicle(vehicleId)),
        onAddReminder: _openAddReminderFlow,
        onEditReminder: _openEditReminderFlow,
        onDeleteReminder: _deleteReminder,
        onEditExpense: _openEditExpenseFlow,
        onDeleteExpense: _deleteExpense,
      ),
      ProfileScreen(
        user: widget.currentUser,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onLogout: widget.onLogout,
        firebaseEnabled: widget.firebaseEnabled,
        usingLocalData: _usingLocalData,
        demoModeEnabled: _demoModeEnabled,
        onDemoModeChanged: _onDemoModeChanged,
        onUpdateProfile: widget.onUpdateProfile,
      ),
    ];

    Widget? fab;
    if (_selectedIndex == 0 || _selectedIndex == 1) {
      fab = FloatingActionButton(
        onPressed: () async {
          final mode = await _showExpenseInputModeSheet();
          if (mode == null) {
            return;
          }
          if (!context.mounted) {
            return;
          }

          final newExpense = await Navigator.of(context).push<CarExpense>(
            MaterialPageRoute(
              builder: (context) =>
                  AddExpenseScreen(vehicles: _vehicles, initialMode: mode),
            ),
          );
          if (newExpense != null) {
            _addExpense(newExpense);
          }
        },
        child: const Icon(Icons.add),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}
