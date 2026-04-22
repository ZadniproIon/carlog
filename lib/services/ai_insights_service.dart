import '../models.dart';

class SpendingAnomaly {
  const SpendingAnomaly({
    required this.vehicleId,
    required this.month,
    required this.totalAmount,
    required this.averageAmount,
  });

  final String vehicleId;
  final DateTime month;
  final double totalAmount;
  final double averageAmount;
}

class PredictedMaintenanceWindow {
  const PredictedMaintenanceWindow({
    required this.vehicleId,
    required this.title,
    this.targetMileage,
    this.targetDate,
  });

  final String vehicleId;
  final String title;
  final int? targetMileage;
  final DateTime? targetDate;
}

class AiInsightsService {
  const AiInsightsService();

  List<SpendingAnomaly> detectMonthlySpendingAnomalies(
    List<CarExpense> expenses,
  ) {
    final grouped = <String, List<CarExpense>>{};
    for (final e in expenses) {
      final key = '${e.vehicleId}-${e.date.year}-${e.date.month}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final perVehicleTotals = <String, List<double>>{};
    grouped.forEach((key, group) {
      final parts = key.split('-');
      if (parts.length < 3) return;
      final vehicleId = parts[0];
      final total = group.fold<double>(0, (sum, e) => sum + e.amount);
      perVehicleTotals.putIfAbsent(vehicleId, () => []).add(total);
    });

    final averages = <String, double>{};
    perVehicleTotals.forEach((vehicleId, totals) {
      if (totals.isEmpty) return;
      final avg = totals.fold<double>(0, (s, v) => s + v) / totals.length;
      averages[vehicleId] = avg;
    });

    final anomalies = <SpendingAnomaly>[];
    grouped.forEach((key, group) {
      final parts = key.split('-');
      if (parts.length < 3) return;
      final vehicleId = parts[0];
      final year = int.parse(parts[1]);
      final month = int.parse(parts[2]);
      final total = group.fold<double>(0, (sum, e) => sum + e.amount);
      final avg = averages[vehicleId] ?? total;
      if (avg == 0) return;
      if (total > avg * 1.5) {
        anomalies.add(
          SpendingAnomaly(
            vehicleId: vehicleId,
            month: DateTime(year, month),
            totalAmount: total,
            averageAmount: avg,
          ),
        );
      }
    });

    return anomalies;
  }

  List<PredictedMaintenanceWindow> predictMaintenanceWindows(
    List<Vehicle> vehicles,
    List<CarExpense> expenses,
  ) {
    final results = <PredictedMaintenanceWindow>[];
    final now = DateTime.now();

    for (final vehicle in vehicles) {
      final vehicleExpenses = expenses
          .where((e) => e.vehicleId == vehicle.id)
          .toList();
      vehicleExpenses.sort((a, b) => a.date.compareTo(b.date));

      final lastService = vehicleExpenses
          .where((e) => e.category == ExpenseCategory.service)
          .toList()
          .lastOrNull;

      if (lastService != null) {
        final targetMileage = lastService.mileage + 15000;
        results.add(
          PredictedMaintenanceWindow(
            vehicleId: vehicle.id,
            title: 'Service interval',
            targetMileage: targetMileage,
            targetDate: now.add(const Duration(days: 180)),
          ),
        );
      }
    }

    return results;
  }
}

extension _IterableLastOrNull<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

