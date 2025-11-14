import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/expense_list_tile.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({
    super.key,
    required this.expenses,
    required this.vehicles,
  });

  final List<CarExpense> expenses;
  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: expenses.isEmpty
          ? const Center(
              child: Text('No expenses yet. Tap "Add expense" to create one.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final vehicle =
                    vehicles.where((v) => v.id == expense.vehicleId).firstOrNull;
                return ExpenseListTile(
                  expense: expense,
                  vehicle: vehicle,
                );
              },
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
