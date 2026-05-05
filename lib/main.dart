import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'theme/app_theme.dart';

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
  ThemeMode _themeMode = ThemeMode.light;
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

  Future<String?> _handleForgotPassword(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return 'Enter a valid email first.';
    }

    if (!widget.firebaseEnabled) {
      return 'Password reset is available only with Firebase auth.';
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmedEmail);
      return null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-email') {
        return 'Please use a valid email address.';
      }
      if (error.code == 'user-not-found') {
        return 'No account found for this email.';
      }
      return error.message ?? 'Could not send reset email.';
    } catch (_) {
      return 'Could not send reset email right now.';
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
    return MaterialApp(
      title: 'CarLog',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: CarlogAppTheme.light(),
      darkTheme: CarlogAppTheme.dark(),
      home: _currentUser == null
          ? AuthScreen(
              onLogin: _handleLogin,
              onSignUp: _handleSignUp,
              onGoogleSignIn: _handleGoogleSignIn,
              onForgotPassword: _handleForgotPassword,
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
  static const String _expenseCurrencyPrefKey = 'expense_currency';
  static const String _fuelPriceCountryPrefKey = 'fuel_price_country';
  static const String _showAnomalyDemoButtonsPrefKey =
      'show_anomaly_demo_buttons';
  static const String _presentationDemoModePrefKey =
      'presentation_demo_mode_enabled';
  static const String _presentationImportExpensePrefix =
      'presentation_import_';
  static const String _sharingRolePrefKey = 'demo_sharing_role';
  static const String _sharedVehiclePackagesPrefKey =
      'demo_shared_vehicle_packages';
  static const String _ownerSharingUserId = 'demo_owner';
  static const String _recipientSharingUserId = 'demo_recipient';
  static const String _ownerSharingName = 'Alex Popa';
  static const String _ownerSharingEmail = 'alex.popa@gmail.com';
  static const String _recipientSharingName = 'Mia Ionescu';
  static const String _recipientSharingEmail = 'mia.ionescu@gmail.com';
  static const String _shareMemberStelaId = 'share_member_stela';
  static const String _shareMemberMihaiId = 'share_member_mihai';
  static const String _shareMemberAnatolieId = 'share_member_anatolie';
  static const String _shareMemberStelaLabel =
      'Stela Zadnipro|stela.zadnipro@gmail.com';
  static const String _shareMemberMihaiLabel =
      'Mihai Zadnipro|mihai.zadnipro@gmail.com';
  static const String _shareMemberAnatolieLabel =
      'Anatolie Zadnipro|anatolie.zadnipro@gmail.com';
  int _selectedIndex = 0;
  late List<Vehicle> _vehicles;
  late List<CarExpense> _expenses;
  late List<MaintenanceReminder> _reminders;
  late List<Vehicle> _ownerVehicles;
  late List<CarExpense> _ownerExpenses;
  late List<MaintenanceReminder> _ownerReminders;
  late List<Vehicle> _recipientVehicles;
  late List<CarExpense> _recipientExpenses;
  late List<MaintenanceReminder> _recipientReminders;
  List<SharedVehiclePackage> _sharedVehiclePackages = <SharedVehiclePackage>[];
  bool _usingLocalData = true;
  bool _demoModeEnabled = true;
  bool _showAnomalyDemoButtons = true;
  bool _presentationDemoModeEnabled = false;
  bool _presentationImportCompleted = false;
  DemoSharingRole _sharingRole = DemoSharingRole.owner;
  ExpenseCurrency _expenseCurrency = ExpenseCurrency.mdl;
  FuelPriceCountry _fuelPriceCountry = FuelPriceCountry.moldova;
  CarlogDataSnapshot? _cachedNonDemoSnapshot;

  @override
  void initState() {
    super.initState();

    _vehicles = <Vehicle>[];
    _expenses = <CarExpense>[];
    _reminders = <MaintenanceReminder>[];
    _ownerVehicles = <Vehicle>[];
    _ownerExpenses = <CarExpense>[];
    _ownerReminders = <MaintenanceReminder>[];
    _recipientVehicles = <Vehicle>[];
    _recipientExpenses = <CarExpense>[];
    _recipientReminders = <MaintenanceReminder>[];

    unawaited(_loadSettings());
    unawaited(_loadInitialData());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrency = prefs.getString(_expenseCurrencyPrefKey);
    final storedFuelCountry = prefs.getString(_fuelPriceCountryPrefKey);
    final storedShowAnomalyDemoButtons = prefs.getBool(
      _showAnomalyDemoButtonsPrefKey,
    );
    final storedPresentationDemoMode = prefs.getBool(
      _presentationDemoModePrefKey,
    );
    final storedSharingRole = prefs.getString(_sharingRolePrefKey);
    final storedSharedPackages = prefs.getString(_sharedVehiclePackagesPrefKey);
    if (!mounted || storedCurrency == null || storedCurrency.trim().isEmpty) {
      if (storedFuelCountry == null || storedFuelCountry.trim().isEmpty) {
        if (storedShowAnomalyDemoButtons == null &&
            storedPresentationDemoMode == null &&
            storedSharingRole == null &&
            storedSharedPackages == null) {
          return;
        }
      }
    }
    final shouldReloadForPresentation = storedPresentationDemoMode == true;
    setState(() {
      if (storedCurrency != null && storedCurrency.trim().isNotEmpty) {
        _expenseCurrency = expenseCurrencyFromKey(storedCurrency);
      }
      if (storedFuelCountry != null && storedFuelCountry.trim().isNotEmpty) {
        _fuelPriceCountry = fuelPriceCountryFromKey(storedFuelCountry);
      }
      if (storedShowAnomalyDemoButtons != null) {
        _showAnomalyDemoButtons = storedShowAnomalyDemoButtons;
      }
      if (storedPresentationDemoMode != null) {
        _presentationDemoModeEnabled = storedPresentationDemoMode;
      }
      if (storedSharingRole == DemoSharingRole.recipient.name) {
        _sharingRole = DemoSharingRole.recipient;
      }
      if (storedSharedPackages != null && storedSharedPackages.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(storedSharedPackages) as List<dynamic>;
          _sharedVehiclePackages = decoded
              .map(
                (item) => SharedVehiclePackage.fromMap(
                  Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
                ),
              )
              .toList();
        } catch (_) {
          _sharedVehiclePackages = <SharedVehiclePackage>[];
        }
      }
    });
    _rebuildVisibleData();
    if (shouldReloadForPresentation) {
      await _loadInitialData(forceRefresh: true);
    }
  }

  String get _activeSharingUserId =>
      _sharingRole == DemoSharingRole.owner
          ? _ownerSharingUserId
          : _recipientSharingUserId;

  Future<void> _saveSharingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sharingRolePrefKey, _sharingRole.name);
    await prefs.setString(
      _sharedVehiclePackagesPrefKey,
      jsonEncode(
        _sharedVehiclePackages.map((package) => package.toMap()).toList(),
      ),
    );
  }

  Future<void> _onExpenseCurrencyChanged(ExpenseCurrency currency) async {
    if (_expenseCurrency == currency) {
      return;
    }
    setState(() {
      _expenseCurrency = currency;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expenseCurrencyPrefKey, currency.name);
  }

  Future<void> _onFuelPriceCountryChanged(FuelPriceCountry country) async {
    if (_fuelPriceCountry == country) {
      return;
    }
    setState(() {
      _fuelPriceCountry = country;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _fuelPriceCountryPrefKey,
      fuelPriceCountryKey(country),
    );
  }

  Future<void> _onShowAnomalyDemoButtonsChanged(bool enabled) async {
    if (_showAnomalyDemoButtons == enabled) {
      return;
    }
    setState(() {
      _showAnomalyDemoButtons = enabled;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAnomalyDemoButtonsPrefKey, enabled);
  }

  Future<void> _onPresentationDemoModeChanged(bool enabled) async {
    if (_presentationDemoModeEnabled == enabled) {
      return;
    }

    setState(() {
      _presentationDemoModeEnabled = enabled;
      _presentationImportCompleted = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_presentationDemoModePrefKey, enabled);
    await _loadInitialData(forceRefresh: true);
  }

  Future<void> _resetPresentationDemo() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _presentationImportCompleted = false;
      _ownerVehicles = List<Vehicle>.from(mockVehicles);
      _ownerExpenses = <CarExpense>[];
      _ownerReminders = <MaintenanceReminder>[];
      _recipientVehicles = <Vehicle>[];
      _recipientExpenses = <CarExpense>[];
      _recipientReminders = <MaintenanceReminder>[];
      _sharedVehiclePackages = <SharedVehiclePackage>[];
      _usingLocalData = true;
      _sharingRole = DemoSharingRole.owner;
      _rebuildVisibleData();
    });
    await _saveSharingState();
  }

  void _removeSharedVehicleIdsFromPrivateData() {
    final sharedIds = _sharedVehiclePackages.map((item) => item.vehicle.id).toSet();
    if (sharedIds.isEmpty) {
      return;
    }
    _ownerVehicles = _ownerVehicles
        .where((vehicle) => !sharedIds.contains(vehicle.id))
        .toList();
    _ownerExpenses = _ownerExpenses
        .where((expense) => !sharedIds.contains(expense.vehicleId))
        .toList();
    _ownerReminders = _ownerReminders
        .where((reminder) => !sharedIds.contains(reminder.vehicleId))
        .toList();
    _recipientVehicles = _recipientVehicles
        .where((vehicle) => !sharedIds.contains(vehicle.id))
        .toList();
    _recipientExpenses = _recipientExpenses
        .where((expense) => !sharedIds.contains(expense.vehicleId))
        .toList();
    _recipientReminders = _recipientReminders
        .where((reminder) => !sharedIds.contains(reminder.vehicleId))
        .toList();
  }

  void _rebuildVisibleData() {
    _removeSharedVehicleIdsFromPrivateData();

    final visiblePackages = _sharedVehiclePackages
        .where((package) => package.access.hasAccess(_activeSharingUserId))
        .toList();

    final privateVehicles = _sharingRole == DemoSharingRole.owner
        ? _ownerVehicles
        : _recipientVehicles;
    final privateExpenses = _sharingRole == DemoSharingRole.owner
        ? _ownerExpenses
        : _recipientExpenses;
    final privateReminders = _sharingRole == DemoSharingRole.owner
        ? _ownerReminders
        : _recipientReminders;

    _vehicles = <Vehicle>[
      ...privateVehicles,
      ...visiblePackages.map((package) => package.vehicle),
    ];
    _expenses = <CarExpense>[
      ...privateExpenses,
      ...visiblePackages.expand((package) => package.expenses),
    ]..sort((a, b) => b.date.compareTo(a.date));
    _reminders = <MaintenanceReminder>[
      ...privateReminders,
      ...visiblePackages.expand((package) => package.reminders),
    ];
    _reminders.sort((a, b) {
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
  }

  List<Vehicle> get _activePrivateVehicles =>
      _sharingRole == DemoSharingRole.owner ? _ownerVehicles : _recipientVehicles;

  List<CarExpense> get _activePrivateExpenses =>
      _sharingRole == DemoSharingRole.owner ? _ownerExpenses : _recipientExpenses;

  List<MaintenanceReminder> get _activePrivateReminders =>
      _sharingRole == DemoSharingRole.owner ? _ownerReminders : _recipientReminders;

  SharedVehiclePackage? _sharedPackageForVehicle(String vehicleId) {
    for (final package in _sharedVehiclePackages) {
      if (package.vehicle.id == vehicleId) {
        return package;
      }
    }
    return null;
  }

  String _generateInviteCode(Vehicle vehicle) {
    final brand = vehicle.brand.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final shortBrand = brand.length <= 3 ? brand : brand.substring(0, 3);
    final suffix = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(7);
    return '$shortBrand-$suffix';
  }

  SharedVehiclePackage? _ensureSharedPackageForVehicle(String vehicleId) {
    final existing = _sharedPackageForVehicle(vehicleId);
    if (existing != null) {
      return existing;
    }

    final vehicleIndex = _ownerVehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (vehicleIndex == -1) {
      return null;
    }

    final vehicle = _ownerVehicles.removeAt(vehicleIndex);
    final expenses = _ownerExpenses.where((expense) => expense.vehicleId == vehicleId).toList();
    final reminders = _ownerReminders
        .where((reminder) => reminder.vehicleId == vehicleId)
        .toList();
    _ownerExpenses.removeWhere((expense) => expense.vehicleId == vehicleId);
    _ownerReminders.removeWhere((reminder) => reminder.vehicleId == vehicleId);

    final package = SharedVehiclePackage(
      vehicle: vehicle,
      expenses: expenses,
      reminders: reminders,
      access: SharedVehicleAccess(
        vehicleId: vehicle.id,
        ownerUserId: _ownerSharingUserId,
        ownerName: _ownerSharingName,
        ownerEmail: _ownerSharingEmail,
        memberUserIds: const <String>[],
        inviteCode: _generateInviteCode(vehicle),
      ),
    );
    _sharedVehiclePackages.add(package);
    return package;
  }

  Future<_JoinSharedVehicleResult> _joinSharedVehicleByCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const _JoinSharedVehicleResult(
        success: false,
        message: 'Enter a valid shared code.',
      );
    }

    for (final vehicleId in _ownerVehicles.map((vehicle) => vehicle.id).toList()) {
      _ensureSharedPackageForVehicle(vehicleId);
    }

    final packageIndex = _sharedVehiclePackages.indexWhere(
      (package) => package.access.inviteCode.toUpperCase() == normalized,
    );
    if (packageIndex == -1) {
      return const _JoinSharedVehicleResult(
        success: false,
        message: 'That shared code is not valid.',
      );
    }

    final package = _sharedVehiclePackages[packageIndex];
    if (package.access.isOwner(_activeSharingUserId)) {
      return const _JoinSharedVehicleResult(
        success: false,
        message: 'Switch to Recipient view to join this vehicle.',
      );
    }
    if (package.access.memberUserIds.contains(_activeSharingUserId)) {
      return _JoinSharedVehicleResult(
        success: true,
        message: 'Vehicle already added.',
        vehicleId: package.vehicle.id,
        ownerName: package.access.ownerName,
        ownerEmail: package.access.ownerEmail,
      );
    }

    setState(() {
      _sharedVehiclePackages[packageIndex] = package.copyWith(
        access: package.access.copyWith(
          memberUserIds: <String>[
            ...package.access.memberUserIds,
            _activeSharingUserId,
          ],
        ),
      );
      _rebuildVisibleData();
    });
    await _saveSharingState();

    return _JoinSharedVehicleResult(
      success: true,
      message: 'Vehicle added.',
      vehicleId: package.vehicle.id,
      ownerName: package.access.ownerName,
      ownerEmail: package.access.ownerEmail,
    );
  }

  Future<void> _revokeSharedVehicleAccess(String vehicleId, String memberUserId) async {
    final index = _sharedVehiclePackages.indexWhere(
      (package) => package.vehicle.id == vehicleId,
    );
    if (index == -1) {
      return;
    }

    setState(() {
      final package = _sharedVehiclePackages[index];
      _sharedVehiclePackages[index] = package.copyWith(
        access: package.access.copyWith(
          memberUserIds: package.access.memberUserIds
              .where((member) => member != memberUserId)
              .toList(),
        ),
      );
      _rebuildVisibleData();
    });
    await _saveSharingState();
  }

  Future<void> _transferSharedVehicleOwnership(String vehicleId) async {
    final index = _sharedVehiclePackages.indexWhere(
      (package) => package.vehicle.id == vehicleId,
    );
    if (index == -1) {
      return;
    }

    setState(() {
      final package = _sharedVehiclePackages[index];
      final nextOwnerUserId = package.access.ownerUserId == _ownerSharingUserId
          ? _recipientSharingUserId
          : _ownerSharingUserId;
      final nextOwnerName = nextOwnerUserId == _ownerSharingUserId
          ? _ownerSharingName
          : _recipientSharingName;
      final nextOwnerEmail = nextOwnerUserId == _ownerSharingUserId
          ? _ownerSharingEmail
          : _recipientSharingEmail;
      final nextMembers = <String>{
        _ownerSharingUserId,
        _recipientSharingUserId,
      }..remove(nextOwnerUserId);
      _sharedVehiclePackages[index] = package.copyWith(
        access: package.access.copyWith(
          ownerUserId: nextOwnerUserId,
          ownerName: nextOwnerName,
          ownerEmail: nextOwnerEmail,
          memberUserIds: nextMembers.toList(),
        ),
      );
      _rebuildVisibleData();
    });
    await _saveSharingState();
  }

  Future<String> _regenerateSharedVehicleCode(String vehicleId) async {
    final index = _sharedVehiclePackages.indexWhere(
      (package) => package.vehicle.id == vehicleId,
    );
    if (index == -1) {
      return '';
    }
    late final String code;
    setState(() {
      final package = _sharedVehiclePackages[index];
      code = _generateInviteCode(package.vehicle);
      _sharedVehiclePackages[index] = package.copyWith(
        access: package.access.copyWith(inviteCode: code),
      );
      _rebuildVisibleData();
    });
    await _saveSharingState();
    return code;
  }

  Future<void> _loadInitialData({bool forceRefresh = false}) async {
    if (_presentationDemoModeEnabled) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ownerVehicles = List<Vehicle>.from(mockVehicles);
        _ownerExpenses = <CarExpense>[];
        _ownerReminders = <MaintenanceReminder>[];
        _recipientVehicles = <Vehicle>[];
        _recipientExpenses = <CarExpense>[];
        _recipientReminders = <MaintenanceReminder>[];
        _presentationImportCompleted = false;
        _usingLocalData = true;
        _rebuildVisibleData();
      });
      return;
    }

    if (_demoModeEnabled) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ownerVehicles = List<Vehicle>.from(mockVehicles);
        _ownerExpenses =
            mockExpenses
                .map(
                  (expense) => expense.copyWith(currency: ExpenseCurrency.mdl),
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        _ownerReminders = buildMockReminders();
        _recipientVehicles = <Vehicle>[];
        _recipientExpenses = <CarExpense>[];
        _recipientReminders = <MaintenanceReminder>[];
        _usingLocalData = true;
        _rebuildVisibleData();
      });
      return;
    }

    if (!forceRefresh && _cachedNonDemoSnapshot != null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ownerVehicles = List<Vehicle>.from(_cachedNonDemoSnapshot!.vehicles);
        _ownerExpenses = List<CarExpense>.from(_cachedNonDemoSnapshot!.expenses);
        _ownerReminders = List<MaintenanceReminder>.from(
          _cachedNonDemoSnapshot!.reminders,
        );
        _recipientVehicles = <Vehicle>[];
        _recipientExpenses = <CarExpense>[];
        _recipientReminders = <MaintenanceReminder>[];
        _usingLocalData = _cachedNonDemoSnapshot!.isLocalOnly;
        _rebuildVisibleData();
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
      _ownerVehicles = List<Vehicle>.from(snapshot.vehicles);
      _ownerExpenses = List<CarExpense>.from(snapshot.expenses);
      _ownerReminders = List<MaintenanceReminder>.from(snapshot.reminders);
      _recipientVehicles = <Vehicle>[];
      _recipientExpenses = <CarExpense>[];
      _recipientReminders = <MaintenanceReminder>[];
      _usingLocalData = snapshot.isLocalOnly;
      _rebuildVisibleData();
    });
  }

  void _addExpense(CarExpense expense) {
    Vehicle? updatedVehicle;
    setState(() {
      final packageIndex = _sharedVehiclePackages.indexWhere(
        (package) => package.vehicle.id == expense.vehicleId,
      );
      if (packageIndex != -1) {
        final package = _sharedVehiclePackages[packageIndex];
        final nextExpenses = <CarExpense>[expense, ...package.expenses]
          ..sort((a, b) => b.date.compareTo(a.date));
        final nextVehicle = expense.mileage > package.vehicle.mileage
            ? package.vehicle.copyWith(mileage: expense.mileage)
            : package.vehicle;
        _sharedVehiclePackages[packageIndex] = package.copyWith(
          vehicle: nextVehicle,
          expenses: nextExpenses,
        );
      } else {
        _activePrivateExpenses.add(expense);
        updatedVehicle = _applyVehicleMileageFromExpense(expense);
      }
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

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
      final packageIndex = _sharedVehiclePackages.indexWhere(
        (package) => package.vehicle.id == expense.vehicleId,
      );
      if (packageIndex != -1) {
        final package = _sharedVehiclePackages[packageIndex];
        final nextExpenses = List<CarExpense>.from(package.expenses);
        final index = nextExpenses.indexWhere((item) => item.id == expense.id);
        if (index == -1) {
          nextExpenses.insert(0, expense);
        } else {
          nextExpenses[index] = expense;
        }
        nextExpenses.sort((a, b) => b.date.compareTo(a.date));
        final nextVehicle = expense.mileage > package.vehicle.mileage
            ? package.vehicle.copyWith(mileage: expense.mileage)
            : package.vehicle;
        _sharedVehiclePackages[packageIndex] = package.copyWith(
          vehicle: nextVehicle,
          expenses: nextExpenses,
        );
      } else {
        final index = _activePrivateExpenses.indexWhere((item) => item.id == expense.id);
        if (index == -1) {
          _activePrivateExpenses.insert(0, expense);
        } else {
          _activePrivateExpenses[index] = expense;
        }
        _activePrivateExpenses.sort((a, b) => b.date.compareTo(a.date));
        updatedVehicle = _applyVehicleMileageFromExpense(expense);
      }
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

    if (!_demoModeEnabled) {
      unawaited(_syncExpense(expense));
      if (updatedVehicle != null) {
        unawaited(_syncVehicle(updatedVehicle!));
      }
    }
  }

  void _deleteExpense(String expenseId) {
    setState(() {
      var removed = false;
      for (var i = 0; i < _sharedVehiclePackages.length; i++) {
        final package = _sharedVehiclePackages[i];
        final nextExpenses =
            package.expenses.where((item) => item.id != expenseId).toList();
        if (nextExpenses.length != package.expenses.length) {
          _sharedVehiclePackages[i] = package.copyWith(expenses: nextExpenses);
          removed = true;
          break;
        }
      }
      if (!removed) {
        _activePrivateExpenses.removeWhere((item) => item.id == expenseId);
      }
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

    if (!_demoModeEnabled) {
      unawaited(_syncDeleteExpense(expenseId));
    }
  }

  void _bulkDeleteExpenses(List<String> expenseIds) {
    final ids = expenseIds.toSet();
    setState(() {
      for (var i = 0; i < _sharedVehiclePackages.length; i++) {
        final package = _sharedVehiclePackages[i];
        _sharedVehiclePackages[i] = package.copyWith(
          expenses: package.expenses
              .where((item) => !ids.contains(item.id))
              .toList(),
        );
      }
      _activePrivateExpenses.removeWhere((item) => ids.contains(item.id));
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

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
    final privateVehicles = _activePrivateVehicles;
    final vehicleIndex = privateVehicles.indexWhere(
      (vehicle) => vehicle.id == expense.vehicleId,
    );
    if (vehicleIndex == -1) {
      return null;
    }

    final existingVehicle = privateVehicles[vehicleIndex];
    if (expense.mileage <= existingVehicle.mileage) {
      return null;
    }

    final updatedVehicle = existingVehicle.copyWith(mileage: expense.mileage);
    privateVehicles[vehicleIndex] = updatedVehicle;
    return updatedVehicle;
  }

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _activePrivateVehicles.add(vehicle);
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

    if (!_demoModeEnabled) {
      unawaited(_syncVehicle(vehicle));
    }
  }

  void _updateVehicle(Vehicle vehicle) {
    setState(() {
      final packageIndex = _sharedVehiclePackages.indexWhere(
        (package) => package.vehicle.id == vehicle.id,
      );
      if (packageIndex != -1) {
        _sharedVehiclePackages[packageIndex] = _sharedVehiclePackages[packageIndex]
            .copyWith(vehicle: vehicle);
      } else {
        final index = _activePrivateVehicles.indexWhere((item) => item.id == vehicle.id);
        if (index == -1) {
          _activePrivateVehicles.add(vehicle);
        } else {
          _activePrivateVehicles[index] = vehicle;
        }
      }
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

    if (!_demoModeEnabled) {
      unawaited(_syncVehicle(vehicle));
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    final isSharedVehicle = _sharedVehiclePackages.any(
      (package) => package.vehicle.id == vehicleId,
    );
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete vehicle?'),
          content: Text(
            isSharedVehicle
                ? 'This removes the shared vehicle and all related expenses/reminders.'
                : 'This removes the vehicle and all related expenses/reminders.',
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
      _sharedVehiclePackages.removeWhere(
        (package) => package.vehicle.id == vehicleId,
      );
      _ownerVehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      _ownerExpenses.removeWhere((expense) => expense.vehicleId == vehicleId);
      _ownerReminders.removeWhere((reminder) => reminder.vehicleId == vehicleId);
      _recipientVehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      _recipientExpenses.removeWhere((expense) => expense.vehicleId == vehicleId);
      _recipientReminders.removeWhere(
        (reminder) => reminder.vehicleId == vehicleId,
      );
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final mode = await _showVehicleAddModeSheet();
    if (mode == null || !mounted) {
      return;
    }

    if (mode == _VehicleAddMode.normal) {
      final newVehicle = await navigator.push<Vehicle>(
        MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
      );
      if (newVehicle != null) {
        _addVehicle(newVehicle);
      }
      return;
    }

    final joinResult = await navigator.push<_JoinSharedVehicleResult>(
      MaterialPageRoute(
        builder: (context) => JoinSharedVehicleScreen(
          onSubmitCode: _joinSharedVehicleByCode,
        ),
      ),
    );
    if (joinResult == null || !joinResult.success || !mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Vehicle added. Shared with you by ${joinResult.ownerName} (${joinResult.ownerEmail}).',
        ),
      ),
    );
  }

  Future<void> _openVehicleSharingManagement(String vehicleId) async {
    final package = _sharedPackageForVehicle(vehicleId) ??
        _ensureSharedPackageForVehicle(vehicleId);
    if (package == null || !mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => VehicleSharingManagementScreen(
          vehicle: package.vehicle,
          access: package.access,
          activeUserId: _activeSharingUserId,
          memberLabels: {
            _ownerSharingUserId: '$_ownerSharingName ($_ownerSharingEmail)',
            _recipientSharingUserId:
                '$_recipientSharingName ($_recipientSharingEmail)',
            _shareMemberStelaId: _shareMemberStelaLabel,
            _shareMemberMihaiId: _shareMemberMihaiLabel,
            _shareMemberAnatolieId: _shareMemberAnatolieLabel,
          },
          onRevokeAccess: (memberUserId) =>
              _revokeSharedVehicleAccess(vehicleId, memberUserId),
          onTransferOwnership: () => _transferSharedVehicleOwnership(vehicleId),
          onRegenerateCode: () => _regenerateSharedVehicleCode(vehicleId),
        ),
      ),
    );
  }

  Future<_VehicleAddMode?> _showVehicleAddModeSheet() {
    return showModalBottomSheet<_VehicleAddMode>(
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
                  'Choose vehicle mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your own vehicle or join one shared with you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: const Icon(LucideIcons.car),
                  title: const Text('Add vehicle'),
                  subtitle: const Text('Create a vehicle in the normal way.'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Navigator.of(context).pop(_VehicleAddMode.normal),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: const Icon(LucideIcons.link2),
                  title: const Text('Join with code'),
                  subtitle: const Text(
                    'Add a vehicle through a shared code from another member.',
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Navigator.of(context).pop(_VehicleAddMode.join),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          initialMode: ExpenseEntryMode.manual,
          preferredCurrency: _expenseCurrency,
          showAnomalyDemoButtons:
              _showAnomalyDemoButtons && !_presentationDemoModeEnabled,
          presentationDemoModeEnabled: _presentationDemoModeEnabled,
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
              onDelete: () => _deleteReminder(reminder.id),
            ),
          ),
        );
    if (updatedReminder != null) {
      _upsertReminder(updatedReminder);
    }
  }

  void _upsertReminder(MaintenanceReminder reminder) {
    setState(() {
      final packageIndex = _sharedVehiclePackages.indexWhere(
        (package) => package.vehicle.id == reminder.vehicleId,
      );
      if (packageIndex != -1) {
        final package = _sharedVehiclePackages[packageIndex];
        final nextReminders = List<MaintenanceReminder>.from(package.reminders);
        final index = nextReminders.indexWhere((item) => item.id == reminder.id);
        if (index == -1) {
          nextReminders.add(reminder);
        } else {
          nextReminders[index] = reminder;
        }
        _sharedVehiclePackages[packageIndex] = package.copyWith(
          reminders: nextReminders,
        );
      } else {
        final index = _activePrivateReminders.indexWhere((item) => item.id == reminder.id);
        if (index == -1) {
          _activePrivateReminders.add(reminder);
        } else {
          _activePrivateReminders[index] = reminder;
        }
      }
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

    if (!_demoModeEnabled) {
      unawaited(_syncReminder(reminder));
    }
  }

  void _deleteReminder(String reminderId) {
    setState(() {
      var removed = false;
      for (var i = 0; i < _sharedVehiclePackages.length; i++) {
        final package = _sharedVehiclePackages[i];
        final nextReminders = package.reminders
            .where((item) => item.id != reminderId)
            .toList();
        if (nextReminders.length != package.reminders.length) {
          _sharedVehiclePackages[i] = package.copyWith(reminders: nextReminders);
          removed = true;
          break;
        }
      }
      if (!removed) {
        _activePrivateReminders.removeWhere((item) => item.id == reminderId);
      }
      _rebuildVisibleData();
    });
    unawaited(_saveSharingState());

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
    // Prototype mode: demo dataset is always enabled.
    _demoModeEnabled = true;
    await _loadInitialData();
  }

  Future<int> _runPresentationDemoImport() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final importedExpenses = _buildPresentationImportExpenses(
      preferredCurrency: _expenseCurrency,
    );
    final preservedExpenses = _expenses
        .where((expense) => !expense.id.startsWith(_presentationImportExpensePrefix))
        .toList();
    final mergedExpenses = <CarExpense>[
      ...preservedExpenses,
      ...importedExpenses,
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) {
      return importedExpenses.length;
    }

    setState(() {
      _expenses = mergedExpenses;
      _reminders = buildMockReminders();
      _presentationImportCompleted = true;
      _usingLocalData = true;
    });

    unawaited(_pushPresentationReminderNotifications());
    return importedExpenses.length;
  }

  Future<void> _pushPresentationReminderNotifications() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    await NotificationService.showReminderNotifications(
      reminders: _reminders,
      vehicles: _vehicles,
    );
  }

  Future<ExpenseEntryMode?> _showExpenseInputModeSheet() {
    const modes = <ExpenseEntryMode>[
      ExpenseEntryMode.smart,
      ExpenseEntryMode.manual,
    ];

    String modeTitle(ExpenseEntryMode mode) {
      switch (mode) {
        case ExpenseEntryMode.smart:
          return 'Smart';
        case ExpenseEntryMode.manual:
          return 'Manual';
      }
    }

    String modeSubtitle(ExpenseEntryMode mode) {
      switch (mode) {
        case ExpenseEntryMode.smart:
          return 'Voice, text, or photo/OCR with AI parsing, then review.';
        case ExpenseEntryMode.manual:
          return 'Fill the form directly.';
      }
    }

    IconData modeIcon(ExpenseEntryMode mode) {
      switch (mode) {
        case ExpenseEntryMode.smart:
          return LucideIcons.sparkles;
        case ExpenseEntryMode.manual:
          return LucideIcons.edit3;
      }
    }

    return showModalBottomSheet<ExpenseEntryMode>(
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
                  'Choose expense mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select how you want to add this expense.',
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
                      trailing: const Icon(LucideIcons.chevronRight),
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
    final sharedAccessByVehicleId = <String, SharedVehicleAccess>{
      for (final package in _sharedVehiclePackages)
        package.vehicle.id: package.access,
    };
    final pages = <Widget>[
      DashboardScreen(
        vehicles: _vehicles,
        expenses: _expenses,
        reminders: _reminders,
        onEditReminder: _openEditReminderFlow,
        fuelPriceCountry: _fuelPriceCountry,
        presentationDemoModeEnabled: _presentationDemoModeEnabled,
        presentationImportCompleted: _presentationImportCompleted,
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
        demoModeEnabled: _demoModeEnabled,
        activeSharingRole: _sharingRole,
        activeSharingUserId: _activeSharingUserId,
        sharedAccessByVehicleId: sharedAccessByVehicleId,
        onAddVehicle: _openAddVehicleFlow,
        onEditVehicle: _openEditVehicleFlow,
        onDeleteVehicle: (vehicleId) => unawaited(_deleteVehicle(vehicleId)),
        onAddReminder: _openAddReminderFlow,
        onEditReminder: _openEditReminderFlow,
        onDeleteReminder: _deleteReminder,
        onEditExpense: _openEditExpenseFlow,
        onDeleteExpense: _deleteExpense,
        onUpdateVehicleMileage: _updateVehicle,
        onManageSharing: _openVehicleSharingManagement,
      ),
      ProfileScreen(
        user: widget.currentUser,
        themeMode: widget.themeMode,
        expenseCurrency: _expenseCurrency,
        fuelPriceCountry: _fuelPriceCountry,
        onThemeModeChanged: widget.onThemeModeChanged,
        onExpenseCurrencyChanged: _onExpenseCurrencyChanged,
        onFuelPriceCountryChanged: _onFuelPriceCountryChanged,
        onLogout: widget.onLogout,
        vehicles: _vehicles,
        firebaseEnabled: widget.firebaseEnabled,
        usingLocalData: _usingLocalData,
        demoModeEnabled: _demoModeEnabled,
        onDemoModeChanged: _onDemoModeChanged,
        onUpdateProfile: widget.onUpdateProfile,
        showAnomalyDemoButtons: _showAnomalyDemoButtons,
        onShowAnomalyDemoButtonsChanged: _onShowAnomalyDemoButtonsChanged,
        presentationDemoModeEnabled: _presentationDemoModeEnabled,
        onPresentationDemoModeChanged: _onPresentationDemoModeChanged,
        onResetPresentationDemo: _resetPresentationDemo,
        onRunPresentationDemoImport: _runPresentationDemoImport,
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
              builder: (context) => AddExpenseScreen(
                vehicles: _vehicles,
                initialMode: mode,
                preferredCurrency: _expenseCurrency,
                showAnomalyDemoButtons:
                    _showAnomalyDemoButtons && !_presentationDemoModeEnabled,
                presentationDemoModeEnabled: _presentationDemoModeEnabled,
              ),
            ),
          );
          if (newExpense != null) {
            _addExpense(newExpense);
          }
        },
        child: const Icon(LucideIcons.plus),
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
            icon: Icon(LucideIcons.layoutDashboard),
            selectedIcon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.receipt),
            selectedIcon: Icon(LucideIcons.receipt),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.car),
            selectedIcon: Icon(LucideIcons.car),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            selectedIcon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

List<CarExpense> _buildPresentationImportExpenses({
  required ExpenseCurrency preferredCurrency,
}) {
  final baseExpenses = mockExpenses
      .map((expense) => expense.copyWith(currency: preferredCurrency))
      .toList();
  final generated = <CarExpense>[];
  final today = DateTime.now();

  for (var i = 0; i < 72; i++) {
    final template = baseExpenses[i % baseExpenses.length];
    final multiplier = 0.94 + ((i % 5) * 0.035);
    final daysAgo = (i * 3) % 210;
    final adjustedDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: daysAgo));

    generated.add(
      template.copyWith(
        id: 'presentation_import_$i',
        amount: double.parse(
          (template.amount * multiplier).toStringAsFixed(0),
        ),
        date: adjustedDate,
        mileage: template.mileage + ((i ~/ 12) * 120),
      ),
    );
  }

  generated.sort((a, b) => b.date.compareTo(a.date));
  return generated;
}

enum _VehicleAddMode { normal, join }

class _JoinSharedVehicleResult {
  const _JoinSharedVehicleResult({
    required this.success,
    required this.message,
    this.vehicleId,
    this.ownerName,
    this.ownerEmail,
  });

  final bool success;
  final String message;
  final String? vehicleId;
  final String? ownerName;
  final String? ownerEmail;
}
