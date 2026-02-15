import 'package:flutter/material.dart';

import 'models.dart';
import 'mock_data.dart';
import 'screens/add_expense_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/vehicles_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _onThemeChanged(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
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
      home: HomeShell(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  late List<Vehicle> _vehicles;
  late List<CarExpense> _expenses;
  late List<MaintenanceReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _vehicles = List<Vehicle>.from(mockVehicles);
    _expenses = List<CarExpense>.from(mockExpenses);
    _reminders = List<MaintenanceReminder>.from(mockReminders);
  }

  void _addExpense(CarExpense expense) {
    setState(() {
      _expenses.insert(0, expense);
    });
  }

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _vehicles.add(vehicle);
    });
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
      ),
      VehiclesScreen(
        vehicles: _vehicles,
        expenses: _expenses,
        reminders: _reminders,
      ),
      ProfileScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    Widget? fab;
    if (_selectedIndex == 0 || _selectedIndex == 1) {
      fab = FloatingActionButton.extended(
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
              ),
            ),
          );
          if (newExpense != null) {
            _addExpense(newExpense);
          }
        },
        label: const Text('Add expense'),
        icon: const Icon(Icons.add),
      );
    } else if (_selectedIndex == 2) {
      fab = FloatingActionButton.extended(
        onPressed: () async {
          final newVehicle = await Navigator.of(context).push<Vehicle>(
            MaterialPageRoute(
              builder: (context) => const AddVehicleScreen(),
            ),
          );
          if (newVehicle != null) {
            _addVehicle(newVehicle);
          }
        },
        label: const Text('Add vehicle'),
        icon: const Icon(Icons.directions_car),
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
