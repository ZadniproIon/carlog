import 'package:flutter/material.dart';

import '../models.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({
    super.key,
    required this.vehicles,
  });

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_filled_outlined),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${vehicle.mileage} km',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        label: 'Year ${vehicle.year}',
                        icon: Icons.calendar_today_outlined,
                      ),
                      _InfoChip(
                        label: vehicle.engine,
                        icon: Icons.speed,
                      ),
                      _InfoChip(
                        label: 'VIN ${vehicle.vin.substring(0, 8)}...',
                        icon: Icons.qr_code_2_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: scheme.primary,
      ),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
