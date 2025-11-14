import 'package:flutter/material.dart';

import '../models.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.vehicle,
  });

  final CarExpense expense;
  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            expenseCategoryIcon(expense.category),
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          expense.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${expenseCategoryLabel(expense.category)} • '
          '${vehicle?.displayName ?? 'Unknown vehicle'}\n'
          '${_formatDate(expense.date)} • ${expense.mileage} km',
        ),
        isThreeLine: true,
        trailing: Text(
          '${expense.amount.toStringAsFixed(0)} lei',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }
}
