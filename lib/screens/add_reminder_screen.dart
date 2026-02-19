import 'package:flutter/material.dart';

import '../models.dart';

enum ReminderDueType { date, mileage }

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({
    super.key,
    required this.vehicleId,
    this.initialReminder,
  });

  final String vehicleId;
  final MaintenanceReminder? initialReminder;

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();
  ReminderDueType _dueType = ReminderDueType.date;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();

    final reminder = widget.initialReminder;
    if (reminder != null) {
      _titleController.text = reminder.title;
      _descriptionController.text = reminder.description;
      if (reminder.dueMileage != null) {
        _dueType = ReminderDueType.mileage;
        _mileageController.text = reminder.dueMileage.toString();
      }
      if (reminder.dueDate != null) {
        _dueDate = reminder.dueDate!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialReminder == null ? 'Add reminder' : 'Edit reminder',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ReminderDueType>(
                segments: const [
                  ButtonSegment(
                    value: ReminderDueType.date,
                    icon: Icon(Icons.calendar_today_outlined),
                    label: Text('Due date'),
                  ),
                  ButtonSegment(
                    value: ReminderDueType.mileage,
                    icon: Icon(Icons.speed),
                    label: Text('Due mileage'),
                  ),
                ],
                selected: {_dueType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _dueType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_dueType == ReminderDueType.date)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Due date'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(_dueDate)),
                        const Icon(Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Due mileage (km)',
                  ),
                  validator: (value) {
                    if (_dueType != ReminderDueType.mileage) {
                      return null;
                    }
                    final mileage = int.tryParse((value ?? '').trim());
                    if (mileage == null || mileage <= 0) {
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
                  widget.initialReminder == null
                      ? 'Save reminder'
                      : 'Update reminder',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (result != null) {
      setState(() => _dueDate = result);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reminder = MaintenanceReminder(
      id:
          widget.initialReminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueType == ReminderDueType.date ? _dueDate : null,
      dueMileage: _dueType == ReminderDueType.mileage
          ? int.parse(_mileageController.text.trim())
          : null,
      vehicleId: widget.vehicleId,
    );

    Navigator.of(context).pop(reminder);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
