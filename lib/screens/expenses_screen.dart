import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/expense_list_tile.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    super.key,
    required this.expenses,
    required this.vehicles,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onBulkDeleteExpenses,
  });

  final List<CarExpense> expenses;
  final List<Vehicle> vehicles;
  final ValueChanged<CarExpense> onEditExpense;
  final ValueChanged<String> onDeleteExpense;
  final ValueChanged<List<String>> onBulkDeleteExpenses;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  Vehicle? _selectedVehicle;
  final Set<String> _selectedExpenseIds = <String>{};

  bool get _isSelectionMode => _selectedExpenseIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _selectedVehicle == null
        ? widget.expenses
        : widget.expenses
              .where((e) => e.vehicleId == _selectedVehicle!.id)
              .toList();

    final selectedCount = _selectedExpenseIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '$selectedCount selected' : 'Expenses'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  tooltip: 'Select all visible',
                  onPressed: () {
                    setState(() {
                      for (final expense in filteredExpenses) {
                        _selectedExpenseIds.add(expense.id);
                      }
                    });
                  },
                  icon: const Icon(Icons.select_all),
                ),
                IconButton(
                  tooltip: 'Delete selected',
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: 'Cancel selection',
                  onPressed: () {
                    setState(() {
                      _selectedExpenseIds.clear();
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ]
            : null,
      ),
      body: widget.expenses.isEmpty
          ? const Center(
              child: Text('No expenses yet. Tap "Add expense" to create one.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Vehicle?>(
                          initialValue: _selectedVehicle,
                          decoration: const InputDecoration(
                            labelText: 'Filter by vehicle',
                          ),
                          items: [
                            const DropdownMenuItem<Vehicle?>(
                              value: null,
                              child: Text('All vehicles'),
                            ),
                            ...widget.vehicles.map(
                              (v) => DropdownMenuItem<Vehicle?>(
                                value: v,
                                child: Text(v.displayName),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicle = value;
                              _selectedExpenseIds.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (filteredExpenses.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No expenses for the selected vehicle.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        final vehicle = widget.vehicles
                            .where((v) => v.id == expense.vehicleId)
                            .firstOrNull;
                        final selected = _selectedExpenseIds.contains(
                          expense.id,
                        );

                        return ExpenseListTile(
                          expense: expense,
                          vehicle: vehicle,
                          isSelected: selected,
                          onLongPress: () => _toggleSelection(expense.id),
                          onTap: _isSelectionMode
                              ? () => _toggleSelection(expense.id)
                              : null,
                          trailing: _isSelectionMode
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) =>
                                      _toggleSelection(expense.id),
                                )
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      widget.onEditExpense(expense);
                                    } else if (value == 'delete') {
                                      widget.onDeleteExpense(expense.id);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  void _toggleSelection(String expenseId) {
    setState(() {
      if (_selectedExpenseIds.contains(expenseId)) {
        _selectedExpenseIds.remove(expenseId);
      } else {
        _selectedExpenseIds.add(expenseId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedExpenseIds.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete selected expenses?'),
          content: Text(
            'This will remove ${_selectedExpenseIds.length} expense(s).',
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

    widget.onBulkDeleteExpenses(_selectedExpenseIds.toList());
    setState(() {
      _selectedExpenseIds.clear();
    });
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
