import 'package:flutter/material.dart';

enum ExpenseCategory { fuel, service, insurance, parts, other }

ExpenseCategory expenseCategoryFromKey(String value) {
  switch (value.toLowerCase().trim()) {
    case 'fuel':
      return ExpenseCategory.fuel;
    case 'service':
      return ExpenseCategory.service;
    case 'insurance':
      return ExpenseCategory.insurance;
    case 'parts':
      return ExpenseCategory.parts;
    default:
      return ExpenseCategory.other;
  }
}

String expenseCategoryLabel(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.fuel:
      return 'Fuel';
    case ExpenseCategory.service:
      return 'Service';
    case ExpenseCategory.insurance:
      return 'Insurance';
    case ExpenseCategory.parts:
      return 'Parts';
    case ExpenseCategory.other:
      return 'Other';
  }
}

IconData expenseCategoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.fuel:
      return Icons.local_gas_station;
    case ExpenseCategory.service:
      return Icons.build;
    case ExpenseCategory.insurance:
      return Icons.shield_outlined;
    case ExpenseCategory.parts:
      return Icons.settings_applications;
    case ExpenseCategory.other:
      return Icons.more_horiz;
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.engine,
    required this.vin,
    required this.mileage,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final String engine;
  final String vin;
  final int mileage;

  String get displayName => '$brand $model';

  Vehicle copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    String? engine,
    String? vin,
    int? mileage,
  }) {
    return Vehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      engine: engine ?? this.engine,
      vin: vin ?? this.vin,
      mileage: mileage ?? this.mileage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'engine': engine,
      'vin': vin,
      'mileage': mileage,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? map['id'] as String
          : DateTime.now().millisecondsSinceEpoch.toString(),
      brand: (map['brand'] as String?)?.trim() ?? 'Unknown brand',
      model: (map['model'] as String?)?.trim() ?? 'Unknown model',
      year: _intFrom(map['year'], fallback: DateTime.now().year),
      engine: (map['engine'] as String?)?.trim() ?? 'Unknown engine',
      vin: (map['vin'] as String?)?.trim() ?? 'N/A',
      mileage: _intFrom(map['mileage']),
    );
  }
}

class CarExpense {
  const CarExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.mileage,
    required this.vehicleId,
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String description;
  final int mileage;
  final String vehicleId;

  CarExpense copyWith({
    String? id,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? description,
    int? mileage,
    String? vehicleId,
  }) {
    return CarExpense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      mileage: mileage ?? this.mileage,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'dateMs': date.millisecondsSinceEpoch,
      'description': description,
      'mileage': mileage,
      'vehicleId': vehicleId,
    };
  }

  factory CarExpense.fromMap(Map<String, dynamic> map) {
    return CarExpense(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? map['id'] as String
          : DateTime.now().millisecondsSinceEpoch.toString(),
      amount: _doubleFrom(map['amount']),
      category: expenseCategoryFromKey((map['category'] ?? 'other').toString()),
      date: _dateFrom(map['dateMs'] ?? map['date'], fallback: DateTime.now()),
      description: (map['description'] as String?)?.trim() ?? 'Car expense',
      mileage: _intFrom(map['mileage']),
      vehicleId: (map['vehicleId'] as String?)?.trim() ?? '',
    );
  }
}

class MaintenanceReminder {
  const MaintenanceReminder({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.dueMileage,
    required this.vehicleId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final int? dueMileage;
  final String vehicleId;

  MaintenanceReminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? dueMileage,
    bool clearDueDate = false,
    bool clearDueMileage = false,
    String? vehicleId,
  }) {
    return MaintenanceReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueMileage: clearDueMileage ? null : (dueMileage ?? this.dueMileage),
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDateMs': dueDate?.millisecondsSinceEpoch,
      'dueMileage': dueMileage,
      'vehicleId': vehicleId,
    };
  }

  factory MaintenanceReminder.fromMap(Map<String, dynamic> map) {
    return MaintenanceReminder(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? map['id'] as String
          : DateTime.now().millisecondsSinceEpoch.toString(),
      title: (map['title'] as String?)?.trim() ?? 'Reminder',
      description: (map['description'] as String?)?.trim() ?? '',
      dueDate: map['dueDateMs'] == null && map['dueDate'] == null
          ? null
          : _dateFrom(map['dueDateMs'] ?? map['dueDate']),
      dueMileage: map['dueMileage'] == null
          ? null
          : _intFrom(map['dueMileage']),
      vehicleId: (map['vehicleId'] as String?)?.trim() ?? '',
    );
  }
}

class MockAuthUser {
  const MockAuthUser({
    required this.name,
    required this.email,
    this.isGuest = false,
    this.uid,
    this.isCloudUser = false,
  });

  final String name;
  final String email;
  final bool isGuest;
  final String? uid;
  final bool isCloudUser;

  MockAuthUser copyWith({
    String? name,
    String? email,
    bool? isGuest,
    String? uid,
    bool? isCloudUser,
  }) {
    return MockAuthUser(
      name: name ?? this.name,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      uid: uid ?? this.uid,
      isCloudUser: isCloudUser ?? this.isCloudUser,
    );
  }

  factory MockAuthUser.guest() {
    return const MockAuthUser(
      name: 'Guest Driver',
      email: 'guest@carlog.local',
      isGuest: true,
    );
  }
}

int _intFrom(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}

double _doubleFrom(Object? value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}

DateTime _dateFrom(Object? value, {DateTime? fallback}) {
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  if (value != null) {
    final candidate = value.toString();
    final timestampMatch = RegExp(r'seconds=(\d+)').firstMatch(candidate);
    if (timestampMatch != null) {
      final seconds = int.tryParse(timestampMatch.group(1)!);
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
  }
  return fallback ?? DateTime.now();
}
