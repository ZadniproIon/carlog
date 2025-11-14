import 'package:flutter/material.dart';

enum ExpenseCategory {
  fuel,
  service,
  insurance,
  parts,
  other,
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
}
