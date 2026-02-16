import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/expense_list_tile.dart';

enum _CategoryPeriod { threeMonths, sixMonths, twelveMonths, allTime }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.vehicles,
    required this.expenses,
    required this.reminders,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _allVehiclesKey = '__all__';

  String? _selectedVehicleId;
  _CategoryPeriod _categoryPeriod = _CategoryPeriod.sixMonths;
  int _touchedPieIndex = -1;
  int _touchedForecastGroupIndex = -1;
  int _touchedForecastRodIndex = -1;
  int _touchedHistogramIndex = -1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filteredExpenses = _buildFilteredExpenses();
    final filteredReminders = _buildFilteredReminders();

    final forecast = _buildForecast(
      expenses: filteredExpenses,
      now: now,
      historyMonths: 6,
      forecastMonths: 6,
    );

    final categoryTotals = _buildCategoryTotals(
      filteredExpenses,
      now: now,
      period: _categoryPeriod,
    );
    final weeklyHistogramBins = _buildWeeklyHistogram(
      filteredExpenses,
      now: now,
      weeks: 12,
    );

    final thisMonthActual = forecast.history.isEmpty
        ? 0.0
        : forecast.history.last.amount;
    final nextMonthPrediction = forecast.predicted.isEmpty
        ? 0.0
        : forecast.predicted.first.amount;
    final forecastSixMonthTotal = forecast.predicted.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final recentExpenses = filteredExpenses.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle scope',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleId ?? _allVehiclesKey,
                      decoration: const InputDecoration(
                        labelText: 'Show analytics for',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: _allVehiclesKey,
                          child: Text('All vehicles'),
                        ),
                        ...widget.vehicles.map(
                          (vehicle) => DropdownMenuItem<String>(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.displayName} (${vehicle.year})',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedVehicleId = value == _allVehiclesKey
                              ? null
                              : value;
                          _touchedPieIndex = -1;
                          _touchedForecastGroupIndex = -1;
                          _touchedForecastRodIndex = -1;
                          _touchedHistogramIndex = -1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'This month',
                    value: '${thisMonthActual.toStringAsFixed(0)} lei',
                    subtitle: 'Actual spending',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    title: 'Next month',
                    value: '${nextMonthPrediction.toStringAsFixed(0)} lei',
                    subtitle: 'Predicted by trend',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ForecastInsightCard(
              slope: forecast.slope,
              projectedSixMonthCost: forecastSixMonthTotal,
            ),
            const SizedBox(height: 12),
            _CategoryDistributionCard(
              categoryTotals: categoryTotals,
              selectedPeriod: _categoryPeriod,
              onPeriodChanged: (period) {
                setState(() {
                  _categoryPeriod = period;
                  _touchedPieIndex = -1;
                });
              },
              touchedIndex: _touchedPieIndex,
              onTouchedIndexChanged: (index) {
                setState(() => _touchedPieIndex = index);
              },
            ),
            const SizedBox(height: 12),
            _MonthlyForecastCard(
              history: forecast.history,
              predicted: forecast.predicted,
              touchedGroupIndex: _touchedForecastGroupIndex,
              touchedRodIndex: _touchedForecastRodIndex,
              onTouchedBarChanged: (groupIndex, rodIndex) {
                setState(() {
                  _touchedForecastGroupIndex = groupIndex;
                  _touchedForecastRodIndex = rodIndex;
                });
              },
            ),
            const SizedBox(height: 12),
            _ExpenseHistogramCard(
              bins: weeklyHistogramBins,
              touchedIndex: _touchedHistogramIndex,
              onTouchedIndexChanged: (index) {
                setState(() => _touchedHistogramIndex = index);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Upcoming maintenance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _MaintenanceList(
              reminders: filteredReminders,
              vehicles: widget.vehicles,
            ),
            const SizedBox(height: 16),
            Text(
              'Recent expenses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (recentExpenses.isEmpty)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No expenses for this scope yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Column(
                children: recentExpenses
                    .map(
                      (expense) => ExpenseListTile(
                        expense: expense,
                        vehicle: widget.vehicles
                            .where((vehicle) => vehicle.id == expense.vehicleId)
                            .firstOrNull,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<CarExpense> _buildFilteredExpenses() {
    final filtered = _selectedVehicleId == null
        ? List<CarExpense>.from(widget.expenses)
        : widget.expenses
              .where((expense) => expense.vehicleId == _selectedVehicleId)
              .toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  List<MaintenanceReminder> _buildFilteredReminders() {
    final filtered = _selectedVehicleId == null
        ? List<MaintenanceReminder>.from(widget.reminders)
        : widget.reminders
              .where((reminder) => reminder.vehicleId == _selectedVehicleId)
              .toList();

    filtered.sort((a, b) {
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastInsightCard extends StatelessWidget {
  const _ForecastInsightCard({
    required this.slope,
    required this.projectedSixMonthCost,
  });

  final double slope;
  final double projectedSixMonthCost;

  @override
  Widget build(BuildContext context) {
    final trend = _trendForSlope(slope);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trend.icon, color: trend.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trend.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Projected cost for the next 6 months: '
              '${projectedSixMonthCost.toStringAsFixed(0)} lei',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disclaimer: Forecast is an estimate based on linear regression over the last 6 monthly totals.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDistributionCard extends StatelessWidget {
  const _CategoryDistributionCard({
    required this.categoryTotals,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.touchedIndex,
    required this.onTouchedIndexChanged,
  });

  final Map<ExpenseCategory, double> categoryTotals;
  final _CategoryPeriod selectedPeriod;
  final ValueChanged<_CategoryPeriod> onPeriodChanged;
  final int touchedIndex;
  final ValueChanged<int> onTouchedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final entries =
        categoryTotals.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    if (entries.isEmpty || total <= 0) {
      return _EmptyAnalyticsCard(
        title: 'Category split (${selectedPeriod.titleLabel})',
        message: 'Add expenses to unlock category analytics.',
      );
    }

    final activeIndex = touchedIndex >= 0 && touchedIndex < entries.length
        ? touchedIndex
        : 0;
    final selectedEntry = entries[activeIndex];
    final selectedPercent = selectedEntry.value / total * 100;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category split (${selectedPeriod.titleLabel})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _CategoryPeriod.values.map((period) {
                return ChoiceChip(
                  label: Text(period.chipLabel),
                  selected: period == selectedPeriod,
                  onSelected: (_) => onPeriodChanged(period),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 34,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        onTouchedIndexChanged(-1);
                        return;
                      }
                      onTouchedIndexChanged(
                        response!.touchedSection!.touchedSectionIndex,
                      );
                    },
                  ),
                  sections: entries.asMap().entries.map((item) {
                    final index = item.key;
                    final entry = item.value;
                    final isSelected = index == activeIndex;
                    final percent = entry.value / total * 100;

                    return PieChartSectionData(
                      color: _categoryColor(context, entry.key),
                      value: entry.value,
                      title:
                          '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%',
                      radius: isSelected ? 64 : 54,
                      titleStyle: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: ${expenseCategoryLabel(selectedEntry.key)} - '
              '${selectedEntry.value.toStringAsFixed(0)} lei '
              '(${selectedPercent.toStringAsFixed(1)}%)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries.asMap().entries.map((item) {
                final index = item.key;
                final entry = item.value;
                final isSelected = index == activeIndex;
                final color = _categoryColor(context, entry.key);
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onTouchedIndexChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.24)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          expenseCategoryLabel(entry.key),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyForecastCard extends StatelessWidget {
  const _MonthlyForecastCard({
    required this.history,
    required this.predicted,
    required this.touchedGroupIndex,
    required this.touchedRodIndex,
    required this.onTouchedBarChanged,
  });

  final List<_MonthAmount> history;
  final List<_MonthAmount> predicted;
  final int touchedGroupIndex;
  final int touchedRodIndex;
  final void Function(int groupIndex, int rodIndex) onTouchedBarChanged;

  @override
  Widget build(BuildContext context) {
    final points = <_ChartMonthPoint>[
      ...history.map(
        (item) => _ChartMonthPoint(
          month: item.month,
          actual: item.amount,
          predicted: 0,
        ),
      ),
      ...predicted.map(
        (item) => _ChartMonthPoint(
          month: item.month,
          actual: 0,
          predicted: item.amount,
        ),
      ),
    ];

    final maxValue = points.fold<double>(
      0,
      (max, point) => math.max(max, math.max(point.actual, point.predicted)),
    );

    if (points.isEmpty || maxValue <= 0) {
      return _EmptyAnalyticsCard(
        title: 'Monthly cost forecast',
        message: 'Add expenses to unlock monthly trend analytics.',
      );
    }

    final maxY = _niceAxisMax(maxValue);
    final selectedPoint =
        touchedGroupIndex >= 0 && touchedGroupIndex < points.length
        ? points[touchedGroupIndex]
        : null;
    final selectedValue = selectedPoint == null || touchedRodIndex < 0
        ? null
        : (touchedRodIndex == 0
              ? selectedPoint.actual
              : selectedPoint.predicted);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly cost forecast (actual vs predicted)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendItem(
                  label: 'Actual',
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _LegendItem(
                  label: 'Predicted',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 270,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _leftAxisInterval(maxY),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: _leftAxisInterval(maxY),
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          if (index.isOdd) {
                            return const SizedBox.shrink();
                          }

                          final month = points[index].month;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatMonthShort(month),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: points.asMap().entries.map((item) {
                    final index = item.key;
                    final point = item.value;

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      showingTooltipIndicators:
                          touchedGroupIndex == index && touchedRodIndex >= 0
                          ? [touchedRodIndex]
                          : const [],
                      barRods: [
                        BarChartRodData(
                          toY: point.actual,
                          width: 8,
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        BarChartRodData(
                          toY: point.predicted,
                          width: 8,
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.spot == null) {
                        onTouchedBarChanged(-1, -1);
                        return;
                      }
                      onTouchedBarChanged(
                        response!.spot!.touchedBarGroupIndex,
                        response.spot!.touchedRodDataIndex,
                      );
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (rod.toY <= 0) {
                          return null;
                        }

                        final point = points[groupIndex];
                        final label = rodIndex == 0 ? 'Actual' : 'Predicted';
                        return BarTooltipItem(
                          '${_formatMonthLong(point.month)}\n'
                          '$label: ${rod.toY.toStringAsFixed(0)} lei',
                          TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedPoint == null ||
                      selectedValue == null ||
                      selectedValue <= 0
                  ? 'Tap a bar to inspect monthly actual and predicted values.'
                  : 'Selected ${_formatMonthLong(selectedPoint.month)}: '
                        '${selectedValue.toStringAsFixed(0)} lei '
                        '(${touchedRodIndex == 0 ? 'Actual' : 'Predicted'})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseHistogramCard extends StatelessWidget {
  const _ExpenseHistogramCard({
    required this.bins,
    required this.touchedIndex,
    required this.onTouchedIndexChanged,
  });

  final List<_HistogramBin> bins;
  final int touchedIndex;
  final ValueChanged<int> onTouchedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final maxCount = bins.fold<int>(0, (max, bin) => math.max(max, bin.count));

    if (bins.isEmpty || maxCount == 0) {
      return _EmptyAnalyticsCard(
        title: 'Expense frequency histogram',
        message: 'No expense activity found for the selected scope.',
      );
    }

    final maxY = math.max(4, maxCount + 1).toDouble();
    final selectedBin = touchedIndex >= 0 && touchedIndex < bins.length
        ? bins[touchedIndex]
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense frequency histogram (weekly)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.30),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0 || value < 0) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= bins.length ||
                              index.isOdd) {
                            return const SizedBox.shrink();
                          }
                          final bin = bins[index];
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatDayMonth(bin.start),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: bins.asMap().entries.map((item) {
                    final index = item.key;
                    final bin = item.value;
                    return BarChartGroupData(
                      x: index,
                      showingTooltipIndicators: touchedIndex == index
                          ? const [0]
                          : const [],
                      barRods: [
                        BarChartRodData(
                          toY: bin.count.toDouble(),
                          width: 10,
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.spot == null) {
                        onTouchedIndexChanged(-1);
                        return;
                      }
                      onTouchedIndexChanged(
                        response!.spot!.touchedBarGroupIndex,
                      );
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bin = bins[groupIndex];
                        return BarTooltipItem(
                          '${_formatDayMonth(bin.start)} - '
                          '${_formatDayMonth(bin.endExclusive.subtract(const Duration(days: 1)))}\n'
                          '${bin.count} expense(s)',
                          TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedBin == null
                  ? 'Tap a column to inspect weekly expense frequency.'
                  : 'Selected week '
                        '${_formatDayMonth(selectedBin.start)} - '
                        '${_formatDayMonth(selectedBin.endExclusive.subtract(const Duration(days: 1)))}: '
                        '${selectedBin.count} expense(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({required this.reminders, required this.vehicles});

  final List<MaintenanceReminder> reminders;
  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No reminders in this scope.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: reminders.map((reminder) {
        final vehicle = vehicles
            .where((item) => item.id == reminder.vehicleId)
            .firstOrNull;
        final dueInfo = _buildDueInfo(reminder);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: Icon(Icons.schedule, color: scheme.primary),
            title: Text(reminder.title),
            subtitle: Text(
              '${vehicle?.displayName ?? 'Vehicle'} - $dueInfo\n'
              '${reminder.description}',
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  String _buildDueInfo(MaintenanceReminder reminder) {
    if (reminder.dueDate != null) {
      return 'Due on ${_formatDate(reminder.dueDate!)}';
    }
    if (reminder.dueMileage != null) {
      return 'Due at ${reminder.dueMileage} km';
    }
    return 'No due date';
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ForecastResult {
  const _ForecastResult({
    required this.history,
    required this.predicted,
    required this.slope,
  });

  final List<_MonthAmount> history;
  final List<_MonthAmount> predicted;
  final double slope;
}

class _MonthAmount {
  const _MonthAmount({required this.month, required this.amount});

  final DateTime month;
  final double amount;
}

class _HistogramBin {
  const _HistogramBin({
    required this.start,
    required this.endExclusive,
    required this.count,
  });

  final DateTime start;
  final DateTime endExclusive;
  final int count;
}

class _ChartMonthPoint {
  const _ChartMonthPoint({
    required this.month,
    required this.actual,
    required this.predicted,
  });

  final DateTime month;
  final double actual;
  final double predicted;
}

class _TrendSignal {
  const _TrendSignal({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}

class _LinearRegression {
  const _LinearRegression({required this.slope, required this.intercept});

  final double slope;
  final double intercept;

  double predict(int x) {
    return intercept + slope * x;
  }

  factory _LinearRegression.fit(List<double> values) {
    if (values.isEmpty) {
      return const _LinearRegression(slope: 0, intercept: 0);
    }

    if (values.length == 1) {
      return _LinearRegression(slope: 0, intercept: values.first);
    }

    final n = values.length;
    final meanX = (n - 1) / 2;
    final meanY = values.reduce((sum, value) => sum + value) / n;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < n; i++) {
      final dx = i - meanX;
      numerator += dx * (values[i] - meanY);
      denominator += dx * dx;
    }

    final slope = denominator == 0 ? 0.0 : numerator / denominator;
    final intercept = meanY - slope * meanX;

    return _LinearRegression(slope: slope, intercept: intercept);
  }
}

_ForecastResult _buildForecast({
  required List<CarExpense> expenses,
  required DateTime now,
  required int historyMonths,
  required int forecastMonths,
}) {
  final thisMonth = DateTime(now.year, now.month);

  final historyMonthsList = List<DateTime>.generate(historyMonths, (index) {
    final offset = historyMonths - 1 - index;
    return DateTime(thisMonth.year, thisMonth.month - offset);
  });

  final totalsByMonth = <DateTime, double>{};
  for (final expense in expenses) {
    final monthKey = DateTime(expense.date.year, expense.date.month);
    totalsByMonth[monthKey] = (totalsByMonth[monthKey] ?? 0) + expense.amount;
  }

  final history = historyMonthsList
      .map(
        (month) =>
            _MonthAmount(month: month, amount: totalsByMonth[month] ?? 0),
      )
      .toList();

  final historyValues = history.map((item) => item.amount).toList();
  final regression = _LinearRegression.fit(historyValues);

  final predicted = List<_MonthAmount>.generate(forecastMonths, (index) {
    final month = DateTime(thisMonth.year, thisMonth.month + index + 1);
    final rawPrediction = regression.predict(historyValues.length + index);
    return _MonthAmount(month: month, amount: math.max(0, rawPrediction));
  });

  return _ForecastResult(
    history: history,
    predicted: predicted,
    slope: regression.slope,
  );
}

Map<ExpenseCategory, double> _buildCategoryTotals(
  List<CarExpense> expenses, {
  required DateTime now,
  required _CategoryPeriod period,
}) {
  final totals = <ExpenseCategory, double>{};
  final since = switch (period) {
    _CategoryPeriod.threeMonths => DateTime(now.year, now.month - 2),
    _CategoryPeriod.sixMonths => DateTime(now.year, now.month - 5),
    _CategoryPeriod.twelveMonths => DateTime(now.year, now.month - 11),
    _CategoryPeriod.allTime => null,
  };

  for (final expense in expenses) {
    if (since != null && expense.date.isBefore(since)) {
      continue;
    }
    totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
  }

  return totals;
}

List<_HistogramBin> _buildWeeklyHistogram(
  List<CarExpense> expenses, {
  required DateTime now,
  required int weeks,
}) {
  final currentWeekStart = _startOfWeek(now);

  return List<_HistogramBin>.generate(weeks, (index) {
    final offset = weeks - 1 - index;
    final start = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day - offset * 7,
    );
    final endExclusive = DateTime(start.year, start.month, start.day + 7);

    final count = expenses.where((expense) {
      return !expense.date.isBefore(start) &&
          expense.date.isBefore(endExclusive);
    }).length;

    return _HistogramBin(
      start: start,
      endExclusive: endExclusive,
      count: count,
    );
  });
}

DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final daysFromMonday = day.weekday - DateTime.monday;
  return DateTime(day.year, day.month, day.day - daysFromMonday);
}

double _niceAxisMax(double maxValue) {
  if (maxValue <= 0) {
    return 10;
  }
  return maxValue * 1.2 + 1;
}

double _leftAxisInterval(double maxY) {
  if (maxY <= 60) {
    return 10;
  }
  if (maxY <= 300) {
    return 50;
  }
  if (maxY <= 1000) {
    return 100;
  }
  if (maxY <= 3000) {
    return 250;
  }
  return 500;
}

_TrendSignal _trendForSlope(double slope) {
  if (slope > 15) {
    return const _TrendSignal(
      title: 'Spending trend is increasing',
      icon: Icons.trending_up,
      color: Color(0xFFEF5350),
    );
  }
  if (slope < -15) {
    return const _TrendSignal(
      title: 'Spending trend is decreasing',
      icon: Icons.trending_down,
      color: Color(0xFF42A5F5),
    );
  }
  return const _TrendSignal(
    title: 'Spending trend is stable',
    icon: Icons.trending_flat,
    color: Color(0xFF66BB6A),
  );
}

Color _categoryColor(BuildContext context, ExpenseCategory category) {
  final scheme = Theme.of(context).colorScheme;

  switch (category) {
    case ExpenseCategory.fuel:
      return scheme.primary;
    case ExpenseCategory.service:
      return const Color(0xFFFB8C00);
    case ExpenseCategory.insurance:
      return const Color(0xFF43A047);
    case ExpenseCategory.parts:
      return const Color(0xFF8E24AA);
    case ExpenseCategory.other:
      return scheme.secondary;
  }
}

String _formatMonthShort(DateTime month) {
  return '${month.month.toString().padLeft(2, '0')}.'
      '${month.year.toString().substring(2)}';
}

String _formatMonthLong(DateTime month) {
  const names = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${names[month.month - 1]} ${month.year}';
}

String _formatDayMonth(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}

extension _CategoryPeriodLabel on _CategoryPeriod {
  String get chipLabel {
    return switch (this) {
      _CategoryPeriod.threeMonths => '3M',
      _CategoryPeriod.sixMonths => '6M',
      _CategoryPeriod.twelveMonths => '12M',
      _CategoryPeriod.allTime => 'All',
    };
  }

  String get titleLabel {
    return switch (this) {
      _CategoryPeriod.threeMonths => 'last 3 months',
      _CategoryPeriod.sixMonths => 'last 6 months',
      _CategoryPeriod.twelveMonths => 'last 12 months',
      _CategoryPeriod.allTime => 'all time',
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
