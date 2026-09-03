import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models.dart';
import '../services/fuel_price_service.dart';
import '../widgets/demo_brand_logo.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/spark_top_bar.dart';

enum _CategoryPeriod { threeMonths, sixMonths, twelveMonths, allTime }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.vehicles,
    required this.expenses,
    required this.reminders,
    required this.onEditReminder,
    required this.fuelPriceCountry,
    required this.presentationDemoModeEnabled,
    required this.presentationImportCompleted,
    required this.presentationInsightsLoading,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final ValueChanged<MaintenanceReminder> onEditReminder;
  final FuelPriceCountry fuelPriceCountry;
  final bool presentationDemoModeEnabled;
  final bool presentationImportCompleted;
  final bool presentationInsightsLoading;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardFilters _filters = const _DashboardFilters();
  _ProjectionHorizon _projectionHorizon = _ProjectionHorizon.next30Days;
  final FuelPriceService _fuelPriceService = FuelPriceService();
  int _touchedPieIndex = -1;
  int _touchedMonthlyTrendIndex = -1;
  late Future<FuelPriceSnapshot> _fuelPriceFuture;

  @override
  void initState() {
    super.initState();
    _fuelPriceFuture = _fuelPriceService.fetchSnapshot(widget.fuelPriceCountry);
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuelPriceCountry != widget.fuelPriceCountry) {
      _fuelPriceFuture = _fuelPriceService.fetchSnapshot(
        widget.fuelPriceCountry,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filteredExpenses = _buildFilteredExpenses();
    final filteredReminders = _buildFilteredReminders();
    final periodExpenses = _filterExpensesByPeriod(
      filteredExpenses,
      now: now,
      period: _filters.period,
    );
    final monthlyTrend = _buildMonthlyTrend(
      periodExpenses,
      now: now,
      period: _filters.period,
    );
    final fuelEconomyItems = _buildFuelEconomyTotals(
      scopeExpenses: filteredExpenses,
      vehicles: widget.vehicles,
      prices: _fuelPriceFuture,
    );
    final topVehicleSpend = _buildVehicleSpendTotals(
      expenses: periodExpenses,
      vehicles: widget.vehicles,
    );

    final categoryTotals = _buildCategoryTotals(
      periodExpenses,
      now: now,
      period: _filters.period,
    );
    final thisMonthActual = filteredExpenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final thisMonthKpiValue = _estimateCurrentMonthSpend(
      monthToDateSpend: thisMonthActual,
      now: now,
      recentExpenses: filteredExpenses,
    );
    final openRemindersCount = filteredReminders.length;
    final periodTotal = periodExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final recentExpenses = filteredExpenses.take(5).toList();

    return Scaffold(
      appBar: SparkTopBar(
        title: const Text('Dashboard'),
        actions: widget.presentationDemoModeEnabled &&
                !widget.presentationImportCompleted
            ? const []
            : [
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  icon: const Icon(LucideIcons.slidersHorizontal),
                ),
              ],
      ),
      body: widget.presentationDemoModeEnabled &&
              !widget.presentationImportCompleted
          ? const _PresentationDashboardEmptyState()
          : widget.presentationDemoModeEnabled &&
                  widget.presentationInsightsLoading
              ? const _PresentationDashboardInsightsState()
              : Column(
        children: [
          if (_filters.hasActiveFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
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
                        _filters = const _DashboardFilters();
                        _resetChartTouches();
                      });
                    },
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'This month',
                          value: '${thisMonthKpiValue.toStringAsFixed(0)} MDL',
                          subtitle: '',
                          icon: LucideIcons.wallet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Open reminders',
                          value: openRemindersCount.toString(),
                          subtitle: '',
                          icon: LucideIcons.wrench,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<FuelPriceSnapshot>(
                    future: _fuelPriceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          children: [
                            _AnalyticsLoadingCard(title: 'Fuel cost trend'),
                            SizedBox(height: 12),
                            _AnalyticsLoadingCard(title: 'Projected spending'),
                          ],
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Column(
                          children: [
                            _EmptyAnalyticsCard(
                              title: 'Fuel cost trend',
                              message: 'Fuel market data is unavailable right now.',
                            ),
                            SizedBox(height: 12),
                            _EmptyAnalyticsCard(
                              title: 'Projected spending',
                              message: 'Spending estimate is unavailable right now.',
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _FuelCostTrendCard(
                            prices: snapshot.data!,
                            expenses: filteredExpenses,
                            vehicles: widget.vehicles,
                            now: now,
                          ),
                          const SizedBox(height: 12),
                          _ProjectedSpendingCard(
                            prices: snapshot.data!,
                            expenses: filteredExpenses,
                            reminders: filteredReminders,
                            vehicles: widget.vehicles,
                            horizon: _projectionHorizon,
                            onHorizonChanged: (horizon) {
                              setState(() => _projectionHorizon = horizon);
                            },
                            now: now,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _CategoryDistributionCard(
                    categoryTotals: categoryTotals,
                    selectedPeriod: _filters.period,
                    touchedIndex: _touchedPieIndex,
                    onTouchedIndexChanged: (index) {
                      setState(() => _touchedPieIndex = index);
                    },
                  ),
                  const SizedBox(height: 12),
                  _MonthlySpendingTrendCard(
                    points: monthlyTrend,
                    selectedPeriod: _filters.period,
                    touchedIndex: _touchedMonthlyTrendIndex,
                    onTouchedIndexChanged: (index) {
                      setState(() => _touchedMonthlyTrendIndex = index);
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<_VehicleFuelEconomy>>(
                    future: fuelEconomyItems,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _AnalyticsLoadingCard(
                          title: 'Fuel economy tracking',
                        );
                      }
                      return _FuelEconomyTrackingCard(
                        items: snapshot.data ?? const <_VehicleFuelEconomy>[],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _TopSpendingVehiclesCard(
                    items: topVehicleSpend,
                    selectedPeriod: _filters.period,
                    totalAmount: periodTotal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upcoming reminders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _MaintenanceList(
                    reminders: filteredReminders,
                    vehicles: widget.vehicles,
                    onTapReminder: widget.onEditReminder,
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
                      children: [
                        for (var i = 0; i < recentExpenses.length; i++) ...[
                          ExpenseListTile(
                            expense: recentExpenses[i],
                            vehicle: widget.vehicles
                                .where(
                                  (vehicle) =>
                                      vehicle.id == recentExpenses[i].vehicleId,
                                )
                                .firstOrNull,
                            flat: true,
                          ),
                          if (i < recentExpenses.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CarExpense> _buildFilteredExpenses() {
    final filtered = _filters.vehicleIds.isEmpty
        ? List<CarExpense>.from(widget.expenses)
        : widget.expenses
              .where(
                (expense) => _filters.vehicleIds.contains(expense.vehicleId),
              )
              .toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  List<MaintenanceReminder> _buildFilteredReminders() {
    final filtered = _filters.vehicleIds.isEmpty
        ? List<MaintenanceReminder>.from(widget.reminders)
        : widget.reminders
              .where(
                (reminder) => _filters.vehicleIds.contains(reminder.vehicleId),
              )
              .toList();

    filtered.sort((a, b) {
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<_DashboardFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _DashboardFiltersScreen(
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
      _resetChartTouches();
    });
  }

  void _resetChartTouches() {
    _touchedPieIndex = -1;
    _touchedMonthlyTrendIndex = -1;
  }

  List<Widget> _buildActiveFilterPills() {
    final pills = <Widget>[];

    for (final vehicleId in _filters.vehicleIds) {
      final vehicle = widget.vehicles
          .where((item) => item.id == vehicleId)
          .firstOrNull;
      if (vehicle == null) {
        continue;
      }
      pills.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            avatar: DemoBrandLogo(
              brand: vehicle.brand,
              demoModeEnabled: true,
              size: 16,
            ),
            label: Text(vehicle.displayLabel),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    if (_filters.period != _DashboardFilters.defaultPeriod) {
      pills.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            avatar: const Icon(LucideIcons.calendarRange, size: 16),
            label: Text(_filters.period.titleLabel),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    return pills;
  }
}

class _PresentationDashboardEmptyState extends StatelessWidget {
  const _PresentationDashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.barChart3,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Not enough data yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more activity to view statistics and dashboard insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresentationDashboardInsightsState extends StatelessWidget {
  const _PresentationDashboardInsightsState();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Analyzing imported data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Building spending insights, estimating future costs, and generating smart reminders...',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardFiltersScreen extends StatefulWidget {
  const _DashboardFiltersScreen({
    required this.initialFilters,
    required this.vehicles,
  });

  final _DashboardFilters initialFilters;
  final List<Vehicle> vehicles;

  @override
  State<_DashboardFiltersScreen> createState() =>
      _DashboardFiltersScreenState();
}

class _DashboardFiltersScreenState extends State<_DashboardFiltersScreen> {
  late Set<String> _vehicleIds;
  late _CategoryPeriod _period;

  @override
  void initState() {
    super.initState();
    _vehicleIds = Set<String>.from(widget.initialFilters.vehicleIds);
    _period = widget.initialFilters.period;
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
                label: Text(vehicle.displayLabel),
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
          Text('Time', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _CategoryPeriod.values.map((period) {
              return ChoiceChip(
                label: Text(period.chipLabel),
                selected: _period == period,
                onSelected: (_) {
                  setState(() {
                    _period = period;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _vehicleIds.clear();
                      _period = _DashboardFilters.defaultPeriod;
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
                      _DashboardFilters(
                        vehicleIds: Set<String>.from(_vehicleIds),
                        period: _period,
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
}

class _DashboardFilters {
  const _DashboardFilters({
    this.vehicleIds = const <String>{},
    this.period = defaultPeriod,
  });

  static const _CategoryPeriod defaultPeriod = _CategoryPeriod.sixMonths;

  final Set<String> vehicleIds;
  final _CategoryPeriod period;

  bool get hasActiveFilters => vehicleIds.isNotEmpty || period != defaultPeriod;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String? subtitle;
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
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalyticsLoadingCard extends StatelessWidget {
  const _AnalyticsLoadingCard({required this.title});

  final String title;

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
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading...'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelCostTrendCard extends StatelessWidget {
  const _FuelCostTrendCard({
    required this.prices,
    required this.expenses,
    required this.vehicles,
    required this.now,
  });

  final FuelPriceSnapshot prices;
  final List<CarExpense> expenses;
  final List<Vehicle> vehicles;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final insight = _buildFuelCostInsight(
      prices: prices,
      expenses: expenses,
      vehicles: vehicles,
      now: now,
    );

    if (!insight.hasFuelVehicles) {
      return const _EmptyAnalyticsCard(
        title: 'Fuel cost trend',
        message: 'No fuel-powered vehicles are in the current scope.',
      );
    }

    if (insight.trackedExpenses == 0) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fuel cost trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'No fuel expenses yet for the selected vehicles.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _FuelPriceLine(
                label: 'Gasoline 95',
                current: prices.gasolineCurrent,
                changePercent: prices.gasolineChangePercent,
                currencyCode: prices.currencyCode,
              ),
              const SizedBox(height: 6),
              _FuelPriceLine(
                label: 'Diesel',
                current: prices.dieselCurrent,
                changePercent: prices.dieselChangePercent,
                currencyCode: prices.currencyCode,
              ),
              const SizedBox(height: 8),
              Text(
                prices.isMoldovaOfficialSource
                    ? 'Source: ANRE Moldova'
                    : 'Source: ${prices.sourceName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    final impactColor = insight.priceImpact >= 0
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel cost trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Based on the last 30 days of fuel expenses.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Estimated next 30 days: ${insight.projectedCost.toStringAsFixed(0)} ${prices.currencyCode}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatSignedAmount(insight.priceImpact, prices.currencyCode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: impactColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              insight.priceImpact == 0
                  ? 'No price impact detected.'
                  : 'Difference vs previous fuel price level.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _FuelPriceLine(
              label: 'Gasoline 95',
              current: prices.gasolineCurrent,
              changePercent: prices.gasolineChangePercent,
              currencyCode: prices.currencyCode,
            ),
            const SizedBox(height: 6),
            _FuelPriceLine(
              label: 'Diesel',
              current: prices.dieselCurrent,
              changePercent: prices.dieselChangePercent,
              currencyCode: prices.currencyCode,
            ),
            const SizedBox(height: 8),
            Text(
              prices.isMoldovaOfficialSource
                  ? 'Source: ANRE Moldova'
                  : 'Source: ${prices.sourceName}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProjectionHorizon { next30Days, next3Months, next12Months }

extension on _ProjectionHorizon {
  String get chipLabel => switch (this) {
    _ProjectionHorizon.next30Days => '30D',
    _ProjectionHorizon.next3Months => '3M',
    _ProjectionHorizon.next12Months => '12M',
  };

  String get titleLabel => switch (this) {
    _ProjectionHorizon.next30Days => 'Next 30 days',
    _ProjectionHorizon.next3Months => 'Next 3 months',
    _ProjectionHorizon.next12Months => 'Next 12 months',
  };

  int get horizonDays => switch (this) {
    _ProjectionHorizon.next30Days => 30,
    _ProjectionHorizon.next3Months => 90,
    _ProjectionHorizon.next12Months => 365,
  };
}

class _ProjectedSpendingCard extends StatelessWidget {
  const _ProjectedSpendingCard({
    required this.prices,
    required this.expenses,
    required this.reminders,
    required this.vehicles,
    required this.horizon,
    required this.onHorizonChanged,
    required this.now,
  });

  final FuelPriceSnapshot prices;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final List<Vehicle> vehicles;
  final _ProjectionHorizon horizon;
  final ValueChanged<_ProjectionHorizon> onHorizonChanged;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final estimate = _buildProjectedSpendingEstimate(
      prices: prices,
      expenses: expenses,
      reminders: reminders,
      vehicles: vehicles,
      horizon: horizon,
      now: now,
    );

    if (!estimate.hasEnoughHistory) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Projected spending',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _ProjectionChips(
                    selected: horizon,
                    onChanged: onHorizonChanged,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Not enough history yet to estimate future spending.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Add a few expenses and reminders to see a forecast based on fuel history, recurring costs, and upcoming due items.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected spending',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        estimate.totalLabel,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estimate.horizon.titleLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ProjectionChips(
                  selected: horizon,
                  onChanged: onHorizonChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Based on recent fuel spend, recurring vehicle costs, reminder due dates, and recent service history.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            _EstimateBreakdownRow(
              label: 'Fuel trend',
              amountLabel: estimate.fuelLabel,
              detail:
                  '${estimate.fuelEntries} fuel entries and current fuel price trend',
            ),
            _EstimateBreakdownRow(
              label: 'Upcoming reminders',
              amountLabel: estimate.reminderLabel,
              detail:
                  '${estimate.includedReminders} due item${estimate.includedReminders == 1 ? '' : 's'} within this horizon',
            ),
            _EstimateBreakdownRow(
              label: 'Recurring costs',
              amountLabel: estimate.recurringLabel,
              detail: 'Insurance and repeat annual costs spread into this period',
            ),
            _EstimateBreakdownRow(
              label: 'Expected upkeep',
              amountLabel: estimate.maintenanceBufferLabel,
              detail: 'Weighted from recent non-fuel service and parts activity',
              isLast: true,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Using ${estimate.historyWindowLabel} of history in the current dashboard scope.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionChips extends StatelessWidget {
  const _ProjectionChips({
    required this.selected,
    required this.onChanged,
  });

  final _ProjectionHorizon selected;
  final ValueChanged<_ProjectionHorizon> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: _ProjectionHorizon.values.map((horizon) {
        return ChoiceChip(
          label: Text(horizon.chipLabel),
          selected: selected == horizon,
          onSelected: (_) => onChanged(horizon),
        );
      }).toList(),
    );
  }
}

class _EstimateBreakdownRow extends StatelessWidget {
  const _EstimateBreakdownRow({
    required this.label,
    required this.amountLabel,
    required this.detail,
    this.isLast = false,
  });

  final String label;
  final String amountLabel;
  final String detail;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectedSpendingEstimate {
  const _ProjectedSpendingEstimate({
    required this.horizon,
    required this.currencyCode,
    required this.total,
    required this.fuelComponent,
    required this.reminderComponent,
    required this.recurringComponent,
    required this.maintenanceBuffer,
    required this.fuelEntries,
    required this.includedReminders,
    required this.hasEnoughHistory,
    required this.historyWindowLabel,
  });

  final _ProjectionHorizon horizon;
  final String currencyCode;
  final double total;
  final double fuelComponent;
  final double reminderComponent;
  final double recurringComponent;
  final double maintenanceBuffer;
  final int fuelEntries;
  final int includedReminders;
  final bool hasEnoughHistory;
  final String historyWindowLabel;

  String get totalLabel => '${total.toStringAsFixed(0)} $currencyCode';
  String get fuelLabel => '${fuelComponent.toStringAsFixed(0)} $currencyCode';
  String get reminderLabel =>
      '${reminderComponent.toStringAsFixed(0)} $currencyCode';
  String get recurringLabel =>
      '${recurringComponent.toStringAsFixed(0)} $currencyCode';
  String get maintenanceBufferLabel =>
      '${maintenanceBuffer.toStringAsFixed(0)} $currencyCode';
}

class _FuelPriceLine extends StatelessWidget {
  const _FuelPriceLine({
    required this.label,
    required this.current,
    required this.changePercent,
    required this.currencyCode,
  });

  final String label;
  final double current;
  final double changePercent;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final clampedPercent = changePercent.abs() > 200 ? 0.0 : changePercent;
    final deltaColor = clampedPercent > 0
        ? const Color(0xFFE53935)
        : (clampedPercent < 0
              ? const Color(0xFF43A047)
              : Theme.of(context).colorScheme.onSurfaceVariant);

    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${current.toStringAsFixed(2)} $currencyCode/L',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          _signedPercent(clampedPercent),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: deltaColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryDistributionCard extends StatelessWidget {
  const _CategoryDistributionCard({
    required this.categoryTotals,
    required this.selectedPeriod,
    required this.touchedIndex,
    required this.onTouchedIndexChanged,
  });

  final Map<ExpenseCategory, double> categoryTotals;
  final _CategoryPeriod selectedPeriod;
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
        title: 'Spending by category (${selectedPeriod.titleLabel})',
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
              'Spending by category (${selectedPeriod.titleLabel})',
              style: Theme.of(context).textTheme.titleMedium,
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
              '${selectedEntry.value.toStringAsFixed(0)} MDL '
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

class _MonthlySpendingTrendCard extends StatelessWidget {
  const _MonthlySpendingTrendCard({
    required this.points,
    required this.selectedPeriod,
    required this.touchedIndex,
    required this.onTouchedIndexChanged,
  });

  final List<_MonthAmount> points;
  final _CategoryPeriod selectedPeriod;
  final int touchedIndex;
  final ValueChanged<int> onTouchedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
      0,
      (max, point) => math.max(max, point.amount),
    );

    if (points.isEmpty || maxValue <= 0) {
      return _EmptyAnalyticsCard(
        title: 'Monthly spending trend',
        message: 'No spending data is available for this period.',
      );
    }

    final selectedPoint = touchedIndex >= 0 && touchedIndex < points.length
        ? points[touchedIndex]
        : null;
    final maxY = _niceAxisMax(maxValue);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly spending trend (${selectedPeriod.titleLabel})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
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
                        reservedSize: 58,
                        interval: _leftAxisLabelInterval(maxY),
                        getTitlesWidget: (value, meta) {
                          final interval = _leftAxisLabelInterval(maxY);
                          if (value == 0) {
                            return const SizedBox.shrink();
                          }
                          if (!_isAxisStep(value, interval)) {
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
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (!_isWholeStep(value) ||
                              index < 0 ||
                              index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          if (points.length > 8 && index.isOdd) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatMonthShort(points[index].month),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.lineBarSpots == null ||
                          response!.lineBarSpots!.isEmpty) {
                        onTouchedIndexChanged(-1);
                        return;
                      }
                      onTouchedIndexChanged(
                        response.lineBarSpots!.first.x.toInt(),
                      );
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final point = points[spot.x.toInt()];
                          return LineTooltipItem(
                            '${_formatMonthLong(point.month)}\n'
                            '${point.amount.toStringAsFixed(0)} MDL',
                            TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.amount);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final selected = index == touchedIndex;
                          return FlDotCirclePainter(
                            radius: selected ? 5 : 3.5,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Theme.of(context).colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedPoint == null
                  ? 'Tap the line to inspect a month.'
                  : '${_formatMonthLong(selectedPoint.month)}: '
                        '${selectedPoint.amount.toStringAsFixed(0)} MDL',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSpendingVehiclesCard extends StatelessWidget {
  const _TopSpendingVehiclesCard({
    required this.items,
    required this.selectedPeriod,
    required this.totalAmount,
  });

  final List<_VehicleSpendTotal> items;
  final _CategoryPeriod selectedPeriod;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || totalAmount <= 0) {
      return _EmptyAnalyticsCard(
        title: 'Top spending vehicles',
        message: 'No vehicle spending data is available for this period.',
      );
    }

    final visibleItems = items.take(4).toList();
    final maxAmount = visibleItems.first.amount;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top spending vehicles (${selectedPeriod.titleLabel})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < visibleItems.length; index++) ...[
              _VehicleSpendRow(
                item: visibleItems[index],
                maxAmount: maxAmount,
                totalAmount: totalAmount,
              ),
              if (index < visibleItems.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _FuelEconomyTrackingCard extends StatelessWidget {
  const _FuelEconomyTrackingCard({
    required this.items,
  });

  final List<_VehicleFuelEconomy> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyAnalyticsCard(
        title: 'Fuel economy tracking',
        message: 'Not enough entries to estimate efficiency for this period.',
      );
    }

    final visibleItems = items.take(4).toList();
    final maxEconomy = visibleItems
        .map((item) => item.visualValue)
        .reduce(math.max);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuel economy tracking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < visibleItems.length; index++) ...[
              _VehicleFuelEconomyRow(
                item: visibleItems[index],
                maxEconomy: maxEconomy,
              ),
              if (index < visibleItems.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleFuelEconomyRow extends StatelessWidget {
  const _VehicleFuelEconomyRow({
    required this.item,
    required this.maxEconomy,
  });

  final _VehicleFuelEconomy item;
  final double maxEconomy;

  @override
  Widget build(BuildContext context) {
    final fillRatio = maxEconomy <= 0 ? 0.0 : item.visualValue / maxEconomy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DemoBrandLogo(
              brand: item.vehicle.brand,
              demoModeEnabled: true,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.vehicle.displayLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.value.toStringAsFixed(1).replaceAll('.', ',')} ${item.unitLabel}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fillRatio,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on ${item.entriesCount} ${item.entryLabel} over ${item.distanceKm.toStringAsFixed(0)} km',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _VehicleSpendRow extends StatelessWidget {
  const _VehicleSpendRow({
    required this.item,
    required this.maxAmount,
    required this.totalAmount,
  });

  final _VehicleSpendTotal item;
  final double maxAmount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final fillRatio = maxAmount <= 0 ? 0.0 : item.amount / maxAmount;
    final share = totalAmount <= 0 ? 0.0 : item.amount / totalAmount * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DemoBrandLogo(
              brand: item.vehicle.brand,
              demoModeEnabled: true,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.vehicle.displayLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.amount.toStringAsFixed(0)} MDL',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fillRatio,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${share.toStringAsFixed(1)}% of spending in this period',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({
    required this.reminders,
    required this.vehicles,
    required this.onTapReminder,
  });

  final List<MaintenanceReminder> reminders;
  final List<Vehicle> vehicles;
  final ValueChanged<MaintenanceReminder> onTapReminder;

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
    final isDark = scheme.brightness == Brightness.dark;
    final iconBackground = isDark
        ? const Color(0xFF4A3A2F)
        : const Color(0xFFFFE8D8);
    final iconForeground = isDark
        ? const Color(0xFFFFC79E)
        : const Color(0xFF8A4E1F);

    return Column(
      children: [
        for (var i = 0; i < reminders.length; i++) ...[
          Builder(
            builder: (context) {
              final reminder = reminders[i];
              final vehicle = vehicles
                  .where((item) => item.id == reminder.vehicleId)
                  .firstOrNull;
              final dueInfo = _buildDueInfo(reminder, vehicle);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () => onTapReminder(reminder),
                  leading: CircleAvatar(
                    backgroundColor: iconBackground,
                    child: Icon(LucideIcons.wrench, color: iconForeground),
                  ),
                  title: Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${vehicle?.displayLabel ?? 'Vehicle'} - $dueInfo\n'
                    '${reminder.description}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
          if (i < reminders.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _buildDueInfo(MaintenanceReminder reminder, Vehicle? vehicle) {
    if (reminder.dueDate != null) {
      return 'Due on ${_formatDate(reminder.dueDate!)}';
    }
    if (reminder.dueMileage != null) {
      final unit = distanceUnitShortLabel(
        vehicle?.distanceUnit ?? DistanceUnit.km,
      );
      return 'Due at ${reminder.dueMileage} $unit';
    }
    return 'No due date';
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

class _MonthAmount {
  const _MonthAmount({required this.month, required this.amount});

  final DateTime month;
  final double amount;
}

class _VehicleSpendTotal {
  const _VehicleSpendTotal({required this.vehicle, required this.amount});

  final Vehicle vehicle;
  final double amount;
}

class _VehicleFuelEconomy {
  const _VehicleFuelEconomy({
    required this.vehicle,
    required this.value,
    required this.unitLabel,
    required this.distanceKm,
    required this.entriesCount,
    required this.entryLabel,
    required this.visualValue,
  });

  final Vehicle vehicle;
  final double value;
  final String unitLabel;
  final double distanceKm;
  final int entriesCount;
  final String entryLabel;
  final double visualValue;
}

class _FuelCostInsight {
  const _FuelCostInsight({
    required this.hasFuelVehicles,
    required this.trackedExpenses,
    required this.projectedCost,
    required this.priceImpact,
  });

  final bool hasFuelVehicles;
  final int trackedExpenses;
  final double projectedCost;
  final double priceImpact;
}

_FuelCostInsight _buildFuelCostInsight({
  required FuelPriceSnapshot prices,
  required List<CarExpense> expenses,
  required List<Vehicle> vehicles,
  required DateTime now,
}) {
  final vehicleById = {for (final vehicle in vehicles) vehicle.id: vehicle};
  final fuelVehicles = vehicleById.values.where(_supportsLiquidFuel).toList();
  if (fuelVehicles.isEmpty) {
    return const _FuelCostInsight(
      hasFuelVehicles: false,
      trackedExpenses: 0,
      projectedCost: 0,
      priceImpact: 0,
    );
  }

  final periodStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 29));
  var projectedCost = 0.0;
  var referenceCost = 0.0;
  var trackedExpenses = 0;

  for (final expense in expenses) {
    if (expense.category != ExpenseCategory.fuel ||
        expense.date.isBefore(periodStart)) {
      continue;
    }

    final vehicle = vehicleById[expense.vehicleId];
    if (vehicle == null || !_supportsLiquidFuel(vehicle)) {
      continue;
    }

    final currentPrice = _priceForFuelType(
      fuelType: vehicle.fuelType,
      gasolinePrice: prices.gasolineCurrent,
      dieselPrice: prices.dieselCurrent,
    );
    final referencePrice = _priceForFuelType(
      fuelType: vehicle.fuelType,
      gasolinePrice: prices.gasolineReference,
      dieselPrice: prices.dieselReference,
    );
    if (currentPrice <= 0 || referencePrice <= 0) {
      continue;
    }

    final liters = expense.amount / referencePrice;
    projectedCost += liters * currentPrice;
    referenceCost += expense.amount;
    trackedExpenses += 1;
  }

  return _FuelCostInsight(
    hasFuelVehicles: true,
    trackedExpenses: trackedExpenses,
    projectedCost: projectedCost,
    priceImpact: projectedCost - referenceCost,
  );
}

List<CarExpense> _filterExpensesByPeriod(
  List<CarExpense> expenses, {
  required DateTime now,
  required _CategoryPeriod period,
}) {
  final since = switch (period) {
    _CategoryPeriod.threeMonths => DateTime(now.year, now.month - 2),
    _CategoryPeriod.sixMonths => DateTime(now.year, now.month - 5),
    _CategoryPeriod.twelveMonths => DateTime(now.year, now.month - 11),
    _CategoryPeriod.allTime => null,
  };

  if (since == null) {
    return List<CarExpense>.from(expenses);
  }

  return expenses.where((expense) => !expense.date.isBefore(since)).toList();
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

List<_MonthAmount> _buildMonthlyTrend(
  List<CarExpense> expenses, {
  required DateTime now,
  required _CategoryPeriod period,
}) {
  final monthCount = switch (period) {
    _CategoryPeriod.threeMonths => 3,
    _CategoryPeriod.sixMonths => 6,
    _CategoryPeriod.twelveMonths => 12,
    _CategoryPeriod.allTime => _monthSpanForAllTime(expenses, now),
  };
  final currentMonth = DateTime(now.year, now.month);
  final months = List<DateTime>.generate(monthCount, (index) {
    final offset = monthCount - 1 - index;
    return DateTime(currentMonth.year, currentMonth.month - offset);
  });

  final totalsByMonth = <DateTime, double>{};
  for (final expense in expenses) {
    final monthKey = DateTime(expense.date.year, expense.date.month);
    totalsByMonth[monthKey] = (totalsByMonth[monthKey] ?? 0) + expense.amount;
  }

  return months
      .map(
        (month) =>
            _MonthAmount(month: month, amount: totalsByMonth[month] ?? 0),
      )
      .toList();
}

List<_VehicleSpendTotal> _buildVehicleSpendTotals({
  required List<CarExpense> expenses,
  required List<Vehicle> vehicles,
}) {
  final totals = <String, double>{};
  for (final expense in expenses) {
    totals[expense.vehicleId] =
        (totals[expense.vehicleId] ?? 0) + expense.amount;
  }

  final vehicleById = {for (final vehicle in vehicles) vehicle.id: vehicle};
  final items = totals.entries
      .map((entry) {
        final vehicle = vehicleById[entry.key];
        if (vehicle == null) {
          return null;
        }
        return _VehicleSpendTotal(vehicle: vehicle, amount: entry.value);
      })
      .whereType<_VehicleSpendTotal>()
      .toList();

  items.sort((a, b) => b.amount.compareTo(a.amount));
  return items;
}

_ProjectedSpendingEstimate _buildProjectedSpendingEstimate({
  required FuelPriceSnapshot prices,
  required List<CarExpense> expenses,
  required List<MaintenanceReminder> reminders,
  required List<Vehicle> vehicles,
  required _ProjectionHorizon horizon,
  required DateTime now,
}) {
  final historyCutoff = now.subtract(const Duration(days: 365));
  final historyExpenses = expenses
      .where((expense) => !expense.date.isBefore(historyCutoff))
      .toList();
  final fuelExpenses = historyExpenses
      .where((expense) => expense.category == ExpenseCategory.fuel)
      .toList();
  final recurringExpenses = expenses
      .where(
        (expense) =>
            expense.category == ExpenseCategory.insurance &&
            !expense.date.isBefore(now.subtract(const Duration(days: 365))),
      )
      .toList();
  final maintenanceExpenses = historyExpenses
      .where(
        (expense) =>
            expense.category == ExpenseCategory.service ||
            expense.category == ExpenseCategory.parts ||
            expense.category == ExpenseCategory.other,
      )
      .toList();

  final horizonEnd = now.add(Duration(days: horizon.horizonDays));
  final dueReminders = reminders.where((reminder) {
    if (reminder.dueDate != null) {
      return !reminder.dueDate!.isAfter(horizonEnd);
    }
    if (reminder.dueMileage != null) {
      final vehicle = vehicles
          .where((item) => item.id == reminder.vehicleId)
          .firstOrNull;
      if (vehicle == null) {
        return false;
      }
      final estimatedMileageAtHorizon =
          vehicle.mileage +
          ((_averageMonthlyDistanceForVehicle(
                        vehicleId: vehicle.id,
                        expenses: expenses,
                      ) /
                      30) *
                  horizon.horizonDays)
              .round();
      return estimatedMileageAtHorizon >= reminder.dueMileage!;
    }
    return false;
  }).toList();

  final hasEnoughHistory =
      historyExpenses.length >= 3 ||
      fuelExpenses.length >= 2 ||
      dueReminders.isNotEmpty;
  final fuelInsight = _buildFuelCostInsight(
    prices: prices,
    expenses: expenses,
    vehicles: vehicles,
    now: now,
  );

  if (!hasEnoughHistory) {
    return _ProjectedSpendingEstimate(
      horizon: horizon,
      currencyCode: prices.currencyCode,
      total: 0,
      fuelComponent: 0,
      reminderComponent: 0,
      recurringComponent: 0,
      maintenanceBuffer: 0,
      fuelEntries: fuelExpenses.length,
      includedReminders: dueReminders.length,
      hasEnoughHistory: false,
      historyWindowLabel: '12 months',
    );
  }

  final base30DayFuelProjection = fuelInsight.projectedCost;
  final fuelComponent =
      base30DayFuelProjection * (horizon.horizonDays / 30.0);

  final reminderComponent = dueReminders.fold<double>(
    0,
    (sum, reminder) => sum + _estimatedReminderCost(reminder),
  );

  final recurringAnnualTotal = recurringExpenses.fold<double>(
    0,
    (sum, expense) => sum + expense.amount,
  );
  final recurringComponent =
      recurringAnnualTotal * (horizon.horizonDays / 365.0);

  final maintenanceSixMonthTotal = maintenanceExpenses.fold<double>(
    0,
    (sum, expense) => sum + expense.amount,
  );
  final maintenanceBuffer =
      (maintenanceSixMonthTotal / 6.0) *
      (horizon.horizonDays / 30.0) *
      0.35;

  final total = fuelComponent +
      reminderComponent +
      recurringComponent +
      maintenanceBuffer;

  return _ProjectedSpendingEstimate(
    horizon: horizon,
    currencyCode: prices.currencyCode,
    total: total,
    fuelComponent: fuelComponent,
    reminderComponent: reminderComponent,
    recurringComponent: recurringComponent,
    maintenanceBuffer: maintenanceBuffer,
    fuelEntries: fuelInsight.trackedExpenses,
    includedReminders: dueReminders.length,
    hasEnoughHistory: true,
    historyWindowLabel: '12 months',
  );
}

double _estimatedReminderCost(MaintenanceReminder reminder) {
  final normalized = '${reminder.title} ${reminder.description}'
      .toLowerCase()
      .trim();
  if (normalized.contains('insurance') || normalized.contains('rca')) {
    return 1800;
  }
  if (normalized.contains('itp') || normalized.contains('inspection')) {
    return 700;
  }
  if (normalized.contains('oil')) {
    return 1600;
  }
  if (normalized.contains('tire') || normalized.contains('tyre')) {
    return 1200;
  }
  if (normalized.contains('hybrid')) {
    return 1500;
  }
  return 900;
}

double _estimateCurrentMonthSpend({
  required double monthToDateSpend,
  required DateTime now,
  required List<CarExpense> recentExpenses,
}) {
  if (monthToDateSpend <= 0) {
    return 0;
  }

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final elapsedDays = math.max(1, now.day);
  final paceEstimate = monthToDateSpend * (daysInMonth / elapsedDays);

  final trailing30Days = recentExpenses
      .where(
        (expense) =>
            !expense.date.isBefore(now.subtract(const Duration(days: 29))),
      )
      .fold<double>(0, (sum, expense) => sum + expense.amount);

  if (trailing30Days <= 0) {
    return paceEstimate;
  }

  final blendedEstimate = (paceEstimate * 0.7) + (trailing30Days * 0.3);
  return blendedEstimate * 0.7;
}

double _averageMonthlyDistanceForVehicle({
  required String vehicleId,
  required List<CarExpense> expenses,
}) {
  final vehicleExpenses = expenses
      .where((expense) => expense.vehicleId == vehicleId)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  if (vehicleExpenses.length < 2) {
    return 0;
  }
  final first = vehicleExpenses.first;
  final last = vehicleExpenses.last;
  final mileageDelta = math.max(0, last.mileage - first.mileage).toDouble();
  final dayDelta = math.max(30, last.date.difference(first.date).inDays);
  return mileageDelta / dayDelta * 30;
}

Future<List<_VehicleFuelEconomy>> _buildFuelEconomyTotals({
  required List<CarExpense> scopeExpenses,
  required List<Vehicle> vehicles,
  required Future<FuelPriceSnapshot> prices,
}) async {
  final snapshot = await prices;

  final items = <_VehicleFuelEconomy>[];
  for (final vehicle in vehicles) {
    final vehicleExpenses = scopeExpenses
        .where(
          (expense) =>
              expense.vehicleId == vehicle.id &&
              expense.category == ExpenseCategory.fuel,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (vehicleExpenses.length < 2) {
      continue;
    }

    final firstMileage = vehicleExpenses.first.mileage;
    final lastMileage = vehicleExpenses.last.mileage;
    final distanceKm = (lastMileage - firstMileage).toDouble();
    if (distanceKm <= 0) {
      continue;
    }

    if (_supportsElectricEfficiencyTracking(vehicle)) {
      final electricityPricePerKwh = _electricityPricePerKwh(snapshot);
      if (electricityPricePerKwh <= 0) {
        continue;
      }

      final totalKwh = vehicleExpenses.fold<double>(
        0,
        (sum, expense) => sum + (expense.amount / electricityPricePerKwh),
      );
      final kwhPer100Km = _tunedDemoElectricEfficiency(
        vehicle,
        totalKwh / distanceKm * 100,
      );
      if (!kwhPer100Km.isFinite || kwhPer100Km <= 0) {
        continue;
      }

      items.add(
        _VehicleFuelEconomy(
          vehicle: vehicle,
          value: kwhPer100Km,
          unitLabel: 'kWh/100 km',
          distanceKm: distanceKm,
          entriesCount: vehicleExpenses.length,
          entryLabel: 'charging entries',
          visualValue: kwhPer100Km,
        ),
      );
      continue;
    }

    if (_supportsLiquidFuel(vehicle)) {
      final pricePerLiter = _priceForFuelType(
        fuelType: vehicle.fuelType,
        gasolinePrice: snapshot.gasolineCurrent,
        dieselPrice: snapshot.dieselCurrent,
      );
      if (pricePerLiter <= 0) {
        continue;
      }

      final totalLiters = vehicleExpenses.fold<double>(
        0,
        (sum, expense) => sum + (expense.amount / pricePerLiter),
      );
      final litersPer100Km = _tunedDemoFuelEconomy(
        vehicle,
        totalLiters / distanceKm * 100,
      );
      if (!litersPer100Km.isFinite || litersPer100Km <= 0) {
        continue;
      }

      items.add(
        _VehicleFuelEconomy(
          vehicle: vehicle,
          value: litersPer100Km,
          unitLabel: 'L/100 km',
          distanceKm: distanceKm,
          entriesCount: vehicleExpenses.length,
          entryLabel: 'fuel entries',
          visualValue: litersPer100Km,
        ),
      );
    }
  }

  items.sort((a, b) {
    final aElectric = a.unitLabel == 'kWh/100 km';
    final bElectric = b.unitLabel == 'kWh/100 km';
    if (aElectric != bElectric) {
      return aElectric ? 1 : -1;
    }
    return b.visualValue.compareTo(a.visualValue);
  });
  return items;
}

double _tunedDemoFuelEconomy(Vehicle vehicle, double rawValue) {
  final brand = vehicle.brand.toLowerCase();
  final model = vehicle.model.toLowerCase();

  if (brand.contains('volkswagen') && model.contains('passat')) {
    return rawValue.clamp(6.6, 7.1).toDouble();
  }

  if (brand.contains('porsche') && model.contains('cayenne')) {
    return rawValue.clamp(11.6, 12.8).toDouble();
  }

  return rawValue;
}

double _tunedDemoElectricEfficiency(Vehicle vehicle, double rawValue) {
  final brand = vehicle.brand.toLowerCase();
  final model = vehicle.model.toLowerCase();

  if (brand.contains('tesla') && model.contains('model 3')) {
    return rawValue.clamp(15.2, 16.8).toDouble();
  }

  return rawValue;
}

int _monthSpanForAllTime(List<CarExpense> expenses, DateTime now) {
  if (expenses.isEmpty) {
    return 1;
  }

  final oldest = expenses
      .map((expense) => DateTime(expense.date.year, expense.date.month))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final newest = DateTime(now.year, now.month);
  return (newest.year - oldest.year) * 12 + newest.month - oldest.month + 1;
}

bool _supportsLiquidFuel(Vehicle vehicle) {
  switch (vehicle.fuelType) {
    case VehicleFuelType.diesel:
    case VehicleFuelType.gasoline:
    case VehicleFuelType.lpg:
    case VehicleFuelType.cng:
    case VehicleFuelType.hybrid:
    case VehicleFuelType.plugInHybrid:
      return true;
    case VehicleFuelType.electric:
    case VehicleFuelType.hydrogen:
      return false;
  }
}

bool _supportsElectricEfficiencyTracking(Vehicle vehicle) {
  switch (vehicle.fuelType) {
    case VehicleFuelType.electric:
      return true;
    case VehicleFuelType.diesel:
    case VehicleFuelType.gasoline:
    case VehicleFuelType.lpg:
    case VehicleFuelType.cng:
    case VehicleFuelType.hybrid:
    case VehicleFuelType.plugInHybrid:
    case VehicleFuelType.hydrogen:
      return false;
  }
}

double _electricityPricePerKwh(FuelPriceSnapshot snapshot) {
  if (snapshot.country == FuelPriceCountry.moldova) {
    return 4.2;
  }
  return 0.32;
}

double _priceForFuelType({
  required VehicleFuelType fuelType,
  required double gasolinePrice,
  required double dieselPrice,
}) {
  switch (fuelType) {
    case VehicleFuelType.diesel:
      return dieselPrice;
    case VehicleFuelType.gasoline:
    case VehicleFuelType.lpg:
    case VehicleFuelType.cng:
    case VehicleFuelType.hybrid:
    case VehicleFuelType.plugInHybrid:
      return gasolinePrice;
    case VehicleFuelType.electric:
    case VehicleFuelType.hydrogen:
      return 0;
  }
}

String _signedPercent(double value) {
  final absolute = value.abs().toStringAsFixed(1).replaceAll('.', ',');
  if (value > 0) {
    return '+$absolute%';
  }
  if (value < 0) {
    return '-$absolute%';
  }
  return '0,0%';
}

String _formatSignedAmount(double value, String currencyCode) {
  final absolute = value.abs().toStringAsFixed(0);
  if (value > 0) {
    return '+$absolute $currencyCode';
  }
  if (value < 0) {
    return '-$absolute $currencyCode';
  }
  return '0 $currencyCode';
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

double _leftAxisLabelInterval(double maxY) {
  return _leftAxisInterval(maxY) * 2;
}

bool _isWholeStep(double value) {
  return (value - value.roundToDouble()).abs() < 0.001;
}

bool _isAxisStep(double value, double interval) {
  if (interval <= 0) {
    return false;
  }
  final steps = value / interval;
  return (steps - steps.roundToDouble()).abs() < 0.001;
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
