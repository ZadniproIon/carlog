import 'package:flutter/material.dart';

import 'models.dart';
import 'mock_data.dart';
import 'screens/add_expense_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/vehicles_screen.dart';

void main() {
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
    return MaterialApp(
      title: 'Smart Car Expenses',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
      ),
      ProfileScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newExpense = await Navigator.of(context).push<CarExpense>(
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(vehicles: _vehicles),
            ),
          );
          if (newExpense != null) {
            _addExpense(newExpense);
          }
        },
        label: const Text('Add expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
