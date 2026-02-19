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
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final MockAuthUser currentUser;
  final VoidCallback onLogout;
  final CarlogRepository repository;
  final bool firebaseEnabled;

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

  @override
  void initState() {
    super.initState();

    _vehicles = const [];
    _expenses = const [];
    _reminders = const [];

    unawaited(_loadPreferencesAndData());
  }

  Future<void> _loadPreferencesAndData() async {
    final preferences = await SharedPreferences.getInstance();
    final demoEnabled = preferences.getBool(_demoModePrefKey) ?? false;
    if (!mounted) {
      return;
    }
    _demoModeEnabled = demoEnabled;
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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

    final snapshot = await widget.repository.loadInitialData(
      user: widget.currentUser,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _vehicles = snapshot.vehicles;
      _expenses = snapshot.expenses;
      _reminders = snapshot.reminders;
      _usingLocalData = snapshot.isLocalOnly;
    });
  }

  void _addExpense(CarExpense expense) {
    setState(() {
      _expenses.insert(0, expense);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncExpense(expense));
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

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _vehicles.add(vehicle);
    });

    if (!_demoModeEnabled) {
      unawaited(_syncVehicle(vehicle));
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

  Future<void> _onDemoModeChanged(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_demoModePrefKey, enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _demoModeEnabled = enabled;
    });
    await _loadInitialData();
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
      ExpensesScreen(expenses: _expenses, vehicles: _vehicles),
      VehiclesScreen(
        vehicles: _vehicles,
        expenses: _expenses,
        reminders: _reminders,
        onAddVehicle: _openAddVehicleFlow,
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
