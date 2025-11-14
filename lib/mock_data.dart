import 'models.dart';

final List<Vehicle> mockVehicles = [
  const Vehicle(
    id: 'v1',
    brand: 'Volkswagen',
    model: 'Golf',
    year: 2015,
    engine: '1.6 TDI',
    vin: 'WVWZZZ1KZFW000001',
    mileage: 145000,
  ),
  const Vehicle(
    id: 'v2',
    brand: 'Dacia',
    model: 'Duster',
    year: 2020,
    engine: '1.5 dCi',
    vin: 'UU1HSDAGXLF000002',
    mileage: 62000,
  ),
  const Vehicle(
    id: 'v3',
    brand: 'Tesla',
    model: 'Model 3',
    year: 2022,
    engine: 'Long Range',
    vin: '5YJ3E1EA7KF000003',
    mileage: 18000,
  ),
];

final List<CarExpense> mockExpenses = [
  CarExpense(
    id: 'e1',
    amount: 280,
    category: ExpenseCategory.fuel,
    date: DateTime.now().subtract(const Duration(days: 2)),
    description: 'Fuel - full tank',
    mileage: 145200,
    vehicleId: 'v1',
  ),
  CarExpense(
    id: 'e2',
    amount: 950,
    category: ExpenseCategory.service,
    date: DateTime.now().subtract(const Duration(days: 10)),
    description: 'Annual service + oil change',
    mileage: 61500,
    vehicleId: 'v2',
  ),
  CarExpense(
    id: 'e3',
    amount: 450,
    category: ExpenseCategory.insurance,
    date: DateTime.now().subtract(const Duration(days: 20)),
    description: 'RCA insurance',
    mileage: 144000,
    vehicleId: 'v1',
  ),
  CarExpense(
    id: 'e4',
    amount: 1200,
    category: ExpenseCategory.parts,
    date: DateTime.now().subtract(const Duration(days: 35)),
    description: 'Brake pads + discs',
    mileage: 142500,
    vehicleId: 'v1',
  ),
  CarExpense(
    id: 'e5',
    amount: 180,
    category: ExpenseCategory.fuel,
    date: DateTime.now().subtract(const Duration(days: 5)),
    description: 'Fuel for weekend trip',
    mileage: 62500,
    vehicleId: 'v2',
  ),
];

final List<MaintenanceReminder> mockReminders = [
  MaintenanceReminder(
    id: 'm1',
    title: 'Oil change',
    description: 'Recommended every 15.000 km or 12 months.',
    dueMileage: 150000,
    vehicleId: 'v1',
  ),
  MaintenanceReminder(
    id: 'm2',
    title: 'ITP (Romanian inspection)',
    description: 'Next technical inspection coming up soon.',
    dueDate: DateTime.now().add(const Duration(days: 45)),
    vehicleId: 'v2',
  ),
  MaintenanceReminder(
    id: 'm3',
    title: 'Brake pads',
    description: 'Check brake pads wear at next service.',
    dueMileage: 65000,
    vehicleId: 'v2',
  ),
];
