import 'package:flutter/material.dart';

import '../models.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.vehicle,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.isSelected = false,
  });

  final CarExpense expense;
  final Vehicle? vehicle;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _categoryPalette(expense.category, scheme);

    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        onTap: onTap ?? () => _showExpenseDetails(context),
        onLongPress: onLongPress,
        selected: isSelected,
        leading: CircleAvatar(
          backgroundColor: palette.background,
          child: Icon(
            expenseCategoryIcon(expense.category),
            color: palette.foreground,
          ),
        ),
        title: Text(
          expense.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${expenseCategoryLabel(expense.category)} • '
              '${vehicle?.displayName ?? 'Unknown vehicle'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(expense.date)} - ${expense.mileage} km',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing:
            trailing ??
            Text(
              '${expense.amount.toStringAsFixed(0)} lei',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _categoryPalette(expense.category, scheme);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: palette.background,
                      child: Icon(
                        expenseCategoryIcon(expense.category),
                        color: palette.foreground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expense.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  expenseCategoryLabel(expense.category),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Amount',
                  value: '${expense.amount.toStringAsFixed(2)} lei',
                ),
                _DetailRow(
                  label: 'Vehicle',
                  value: vehicle?.displayName ?? 'Unknown vehicle',
                ),
                _DetailRow(label: 'Date', value: _formatDateFull(expense.date)),
                _DetailRow(label: 'Mileage', value: '${expense.mileage} km'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDateFull(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  _CategoryPalette _categoryPalette(
    ExpenseCategory category,
    ColorScheme scheme,
  ) {
    final isDark = scheme.brightness == Brightness.dark;

    switch (category) {
      case ExpenseCategory.fuel:
        return _CategoryPalette(
          background: isDark
              ? const Color(0xFF2E3B52)
              : const Color(0xFFDDEBFF),
          foreground: isDark
              ? const Color(0xFFAED0FF)
              : const Color(0xFF335B8F),
        );
      case ExpenseCategory.service:
        return _CategoryPalette(
          background: isDark
              ? const Color(0xFF4A3A2F)
              : const Color(0xFFFFE8D8),
          foreground: isDark
              ? const Color(0xFFFFC79E)
              : const Color(0xFF8A4E1F),
        );
      case ExpenseCategory.insurance:
        return _CategoryPalette(
          background: isDark
              ? const Color(0xFF2A4036)
              : const Color(0xFFDFF3E8),
          foreground: isDark
              ? const Color(0xFFA6DCC0)
              : const Color(0xFF2D6A4F),
        );
      case ExpenseCategory.parts:
        return _CategoryPalette(
          background: isDark
              ? const Color(0xFF3A344C)
              : const Color(0xFFECE7FF),
          foreground: isDark
              ? const Color(0xFFC6BAFF)
              : const Color(0xFF5A4A99),
        );
      case ExpenseCategory.other:
        return _CategoryPalette(
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPalette {
  const _CategoryPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
