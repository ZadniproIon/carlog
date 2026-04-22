import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/demo_brand_logo.dart';
import '../widgets/spark_top_bar.dart';

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
  final Set<String> _selectedExpenseIds = <String>{};
  _ExpenseFilters _filters = const _ExpenseFilters();

  bool get _isSelectionMode => _selectedExpenseIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _buildFilteredExpenses();
    final selectedCount = _selectedExpenseIds.length;

    return Scaffold(
      appBar: SparkTopBar(
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
                  icon: const Icon(LucideIcons.checkSquare),
                ),
                IconButton(
                  tooltip: 'Delete selected',
                  onPressed: _deleteSelected,
                  icon: const Icon(LucideIcons.trash2),
                ),
                IconButton(
                  tooltip: 'Cancel selection',
                  onPressed: () {
                    setState(() {
                      _selectedExpenseIds.clear();
                    });
                  },
                  icon: const Icon(LucideIcons.x),
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  icon: const Icon(LucideIcons.slidersHorizontal),
                ),
              ],
      ),
      body: widget.expenses.isEmpty
          ? const Center(
              child: Text('No expenses yet. Tap "Add expense" to create one.'),
            )
          : Column(
              children: [
                if (_filters.hasActiveFilters)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: _buildActiveFilterPills()),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Clear filters',
                          onPressed: () {
                            setState(() {
                              _filters = const _ExpenseFilters();
                              _selectedExpenseIds.clear();
                            });
                          },
                          icon: const Icon(LucideIcons.x, size: 18),
                        ),
                      ],
                    ),
                  ),
                if (filteredExpenses.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No expenses match your current filters.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          flat: true,
                          isSelected: selected,
                          onEdit: _isSelectionMode
                              ? null
                              : () {
                                  widget.onEditExpense(expense);
                                },
                          onDelete: _isSelectionMode
                              ? null
                              : () {
                                  widget.onDeleteExpense(expense.id);
                                },
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
                              : null,
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(context).dividerColor,
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  List<CarExpense> _buildFilteredExpenses() {
    final filtered = widget.expenses.where((expense) {
      if (_filters.vehicleIds.isNotEmpty &&
          !_filters.vehicleIds.contains(expense.vehicleId)) {
        return false;
      }
      if (_filters.categories.isNotEmpty &&
          !_filters.categories.contains(expense.category)) {
        return false;
      }

      final expenseDay = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (_filters.startDate != null) {
        final start = DateTime(
          _filters.startDate!.year,
          _filters.startDate!.month,
          _filters.startDate!.day,
        );
        if (expenseDay.isBefore(start)) {
          return false;
        }
      }

      if (_filters.endDate != null) {
        final end = DateTime(
          _filters.endDate!.year,
          _filters.endDate!.month,
          _filters.endDate!.day,
        );
        if (expenseDay.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<_ExpenseFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ExpenseFiltersScreen(
          initialFilters: _filters,
          vehicles: widget.vehicles,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _filters = result;
      _selectedExpenseIds.clear();
    });
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

  List<Widget> _buildActiveFilterPills() {
    final pills = <Widget>[];

    for (final vehicleId in _filters.vehicleIds) {
      final vehicle = widget.vehicles
          .where((v) => v.id == vehicleId)
          .firstOrNull;
      if (vehicle == null) continue;
      pills.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            avatar: DemoBrandLogo(
              brand: vehicle.brand,
              demoModeEnabled: true,
              size: 16,
            ),
            label: Text(vehicle.displayName),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    for (final category in _filters.categories) {
      pills.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            avatar: Icon(expenseCategoryIcon(category), size: 16),
            label: Text(expenseCategoryLabel(category)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    if (_filters.startDate != null || _filters.endDate != null) {
      final from = _filters.startDate == null
          ? 'Any'
          : _formatDate(_filters.startDate!);
      final to = _filters.endDate == null
          ? 'Any'
          : _formatDate(_filters.endDate!);
      pills.add(
        Chip(
          avatar: const Icon(LucideIcons.calendar, size: 16),
          label: Text('$from - $to'),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return pills;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}

class _ExpenseFiltersScreen extends StatefulWidget {
  const _ExpenseFiltersScreen({
    required this.initialFilters,
    required this.vehicles,
  });

  final _ExpenseFilters initialFilters;
  final List<Vehicle> vehicles;

  @override
  State<_ExpenseFiltersScreen> createState() => _ExpenseFiltersScreenState();
}

class _ExpenseFiltersScreenState extends State<_ExpenseFiltersScreen> {
  late Set<String> _vehicleIds;
  late Set<ExpenseCategory> _categories;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _vehicleIds = Set<String>.from(widget.initialFilters.vehicleIds);
    _categories = Set<ExpenseCategory>.from(widget.initialFilters.categories);
    _startDate = widget.initialFilters.startDate;
    _endDate = widget.initialFilters.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SparkTopBar(title: Text('Filters')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Text('Vehicles', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.vehicles.map((vehicle) {
              final selected = _vehicleIds.contains(vehicle.id);
              return FilterChip(
                selected: selected,
                label: Text(vehicle.displayName),
                avatar: DemoBrandLogo(
                  brand: vehicle.brand,
                  demoModeEnabled: true,
                  size: 16,
                ),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _vehicleIds.add(vehicle.id);
                    } else {
                      _vehicleIds.remove(vehicle.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Categories', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((category) {
              final selected = _categories.contains(category);
              return FilterChip(
                selected: selected,
                label: Text(expenseCategoryLabel(category)),
                avatar: Icon(expenseCategoryIcon(category), size: 16),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _categories.add(category);
                    } else {
                      _categories.remove(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Date range', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(
                    _startDate == null
                        ? 'Start date'
                        : _formatDate(_startDate!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(
                    _endDate == null ? 'End date' : _formatDate(_endDate!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Last 30 days'),
                onPressed: () => _setLastDays(30),
              ),
              ActionChip(
                label: const Text('Last 90 days'),
                onPressed: () => _setLastDays(90),
              ),
              ActionChip(
                label: const Text('This year'),
                onPressed: _setThisYear,
              ),
              ActionChip(
                label: const Text('All time'),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _vehicleIds.clear();
                      _categories.clear();
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _ExpenseFilters(
                        vehicleIds: Set<String>.from(_vehicleIds),
                        categories: Set<ExpenseCategory>.from(_categories),
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      if (_startDate != null && _startDate!.isAfter(picked)) {
        _startDate = picked;
      }
    });
  }

  void _setLastDays(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = _endDate!.subtract(Duration(days: days - 1));
    });
  }

  void _setThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}

class _ExpenseFilters {
  const _ExpenseFilters({
    this.vehicleIds = const <String>{},
    this.categories = const <ExpenseCategory>{},
    this.startDate,
    this.endDate,
  });

  final Set<String> vehicleIds;
  final Set<ExpenseCategory> categories;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasActiveFilters =>
      vehicleIds.isNotEmpty ||
      categories.isNotEmpty ||
      startDate != null ||
      endDate != null;

  String summary(List<Vehicle> vehicles) {
    final parts = <String>[];
    if (vehicleIds.isNotEmpty) {
      final selectedNames = vehicles
          .where((v) => vehicleIds.contains(v.id))
          .map((v) => v.displayName)
          .toList();
      if (selectedNames.length <= 2) {
        parts.add(selectedNames.join(', '));
      } else {
        parts.add('${selectedNames.length} vehicles');
      }
    }
    if (categories.isNotEmpty) {
      if (categories.length <= 2) {
        parts.add(categories.map(expenseCategoryLabel).join(', '));
      } else {
        parts.add('${categories.length} categories');
      }
    }
    if (startDate != null || endDate != null) {
      final from = startDate == null
          ? 'Any'
          : '${startDate!.day.toString().padLeft(2, '0')}.'
                '${startDate!.month.toString().padLeft(2, '0')}.'
                '${startDate!.year}';
      final to = endDate == null
          ? 'Any'
          : '${endDate!.day.toString().padLeft(2, '0')}.'
                '${endDate!.month.toString().padLeft(2, '0')}.'
                '${endDate!.year}';
      parts.add('$from - $to');
    }
    return parts.join('  •  ');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
