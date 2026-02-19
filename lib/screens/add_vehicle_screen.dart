import 'package:flutter/material.dart';

import '../models.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key, this.initialVehicle});

  final Vehicle? initialVehicle;

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _engineController = TextEditingController();
  final _vinController = TextEditingController();
  final _mileageController = TextEditingController();

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final vehicle = widget.initialVehicle;
    if (vehicle != null) {
      _brandController.text = vehicle.brand;
      _modelController.text = vehicle.model;
      _yearController.text = vehicle.year.toString();
      _engineController.text = vehicle.engine;
      _vinController.text = vehicle.vin;
      _mileageController.text = vehicle.mileage.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialVehicle == null ? 'Add vehicle' : 'Edit vehicle',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year';
                  }
                  final year = int.tryParse(value);
                  if (year == null ||
                      year < 1990 ||
                      year > DateTime.now().year + 1) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _engineController,
                decoration: const InputDecoration(
                  labelText: 'Engine',
                  hintText: 'e.g. 1.5 dCi, Long Range',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current mileage (km)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mileage';
                  }
                  final mileage = int.tryParse(value);
                  if (mileage == null || mileage < 0) {
                    return 'Enter a valid mileage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.initialVehicle == null
                      ? 'Save vehicle'
                      : 'Update vehicle',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vehicle = Vehicle(
      id:
          widget.initialVehicle?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text),
      engine: _engineController.text.trim().isEmpty
          ? 'Unknown engine'
          : _engineController.text.trim(),
      vin: _vinController.text.trim().isEmpty
          ? 'N/A'
          : _vinController.text.trim(),
      mileage: int.parse(_mileageController.text),
    );

    Navigator.of(context).pop(vehicle);
  }
}
