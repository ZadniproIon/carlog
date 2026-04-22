import 'package:flutter/material.dart';

import '../models.dart';

enum CategoryChartRange { last30Days, last90Days, last12Months, allTime }

class CategoryChart extends StatefulWidget {
  const CategoryChart({
    super.key,
    required this.categoryTotals,
    this.expenseTimeline,
  });

  final Map<ExpenseCategory, double> categoryTotals;
  final List<CarExpense>? expenseTimeline;

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  CategoryChartRange _range = CategoryChartRange.last90Days;

  @override
  Widget build(BuildContext context) {
    final totals = _buildVisibleTotals();
    final maxTotal = totals.values.fold<double>(
      0,
      (prev, e) => e > prev ? e : prev,
    );
    final safeMaxTotal = maxTotal <= 0 ? 1.0 : maxTotal;

    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.expenseTimeline != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryChartRange.values.map((value) {
                  final selected = value == _range;
                  return ChoiceChip(
                    label: Text(_rangeLabel(value)),
                    selected: selected,
                    onSelected: (_) => setState(() => _range = value),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            if (maxTotal == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'No expenses in this period yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ..._buildRows(
              context: context,
              totals: totals,
              maxTotal: safeMaxTotal,
              scheme: scheme,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows({
    required BuildContext context,
    required Map<ExpenseCategory, double> totals,
    required double maxTotal,
    required ColorScheme scheme,
  }) {
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (var i = 0; i < entries.length; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              child: Text(
                '${entries[i].value.toStringAsFixed(0)} lei',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expenseCategoryLabel(entries[i].key),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: entries[i].value / maxTotal,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              expenseCategoryIcon(entries[i].key),
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
        if (i < entries.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  Map<ExpenseCategory, double> _buildVisibleTotals() {
    final totals = <ExpenseCategory, double>{
      for (final category in ExpenseCategory.values) category: 0,
    };

    final timeline = widget.expenseTimeline;
    if (timeline == null) {
      for (final entry in widget.categoryTotals.entries) {
        totals[entry.key] = entry.value;
      }
      return totals;
    }

    final now = DateTime.now();
    DateTime? start;
    switch (_range) {
      case CategoryChartRange.last30Days:
        start = now.subtract(const Duration(days: 30));
      case CategoryChartRange.last90Days:
        start = now.subtract(const Duration(days: 90));
      case CategoryChartRange.last12Months:
        start = DateTime(now.year - 1, now.month, now.day);
      case CategoryChartRange.allTime:
        start = null;
    }

    for (final expense in timeline) {
      if (start != null && expense.date.isBefore(start)) {
        continue;
      }
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  String _rangeLabel(CategoryChartRange range) {
    switch (range) {
      case CategoryChartRange.last30Days:
        return '30d';
      case CategoryChartRange.last90Days:
        return '90d';
      case CategoryChartRange.last12Months:
        return '12m';
      case CategoryChartRange.allTime:
        return 'All';
    }
  }

}

