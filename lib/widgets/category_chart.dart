import 'package:flutter/material.dart';

import '../models.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({
    super.key,
    required this.categoryTotals,
  });

  final Map<ExpenseCategory, double> categoryTotals;

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return _buildPlaceholder(context);
    }

    final maxTotal =
        categoryTotals.values.fold<double>(0, (prev, e) => e > prev ? e : prev);

    if (maxTotal == 0) {
      return _buildPlaceholder(context);
    }

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
              'By category (this month)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: categoryTotals.entries.map((entry) {
                  final height = (entry.value / maxTotal) * 100;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                scheme.primaryContainer,
                                scheme.primary,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expenseCategoryLabel(entry.key),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses chart',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see a simple chart.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
