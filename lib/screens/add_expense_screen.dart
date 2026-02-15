import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/nlp_expense_analyzer.dart';
import '../services/speech_recognition_service.dart';

enum ExpenseInputMode {
  manual,
  text,
  voice,
}

enum ExpenseWizardStep {
  textInput,
  voiceInput,
  manualForm,
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.vehicles,
    required this.initialMode,
  });

  final List<Vehicle> vehicles;
  final ExpenseInputMode initialMode;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _textInputController = TextEditingController();
  final _voiceInputController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();

  final _nlpAnalyzer = const NlpExpenseAnalyzer();
  final _speechService = SpeechRecognitionService();

  StreamSubscription<SpeechRecognitionStatus>? _speechStatusSubscription;
  StreamSubscription<SpeechRecognitionResult>? _speechResultSubscription;

  late ExpenseWizardStep _step;
  SpeechRecognitionStatus _voiceStatus = SpeechRecognitionStatus.idle;

  ExpenseCategory _category = ExpenseCategory.fuel;
  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  late final String? _initialVehicleId;
  late final DateTime _initialDate;

  bool _isParsing = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();

    _step = _stepForMode(widget.initialMode);

    if (widget.vehicles.isNotEmpty) {
      _selectedVehicle = widget.vehicles.first;
    }
    _initialVehicleId = _selectedVehicle?.id;
    _initialDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    _speechStatusSubscription = _speechService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _voiceStatus = status;
      });
    });

    _speechResultSubscription = _speechService.resultsStream.listen((result) {
      if (!mounted || result.text.trim().isEmpty) return;
      _voiceInputController.text = result.text.trim();
      _voiceInputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _voiceInputController.text.length),
      );
    });
  }

  @override
  void dispose() {
    _speechStatusSubscription?.cancel();
    _speechResultSubscription?.cancel();
    unawaited(_speechService.dispose());

    _textInputController.dispose();
    _voiceInputController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final shouldPop = await _confirmDiscardIfNeeded();
        if (!context.mounted || !shouldPop) return;

        _allowPop = true;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add expense'),
        ),
        body: SafeArea(
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case ExpenseWizardStep.textInput:
        return _buildTextInputStep();
      case ExpenseWizardStep.voiceInput:
        return _buildVoiceInputStep();
      case ExpenseWizardStep.manualForm:
        return _buildManualFormStep();
    }
  }

  Widget _buildTextInputStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Text input',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Describe the expense, then continue to the form and complete missing details.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _textInputController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Example: am alimentat cu 350 lei pentru Passat, 186000 km',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isParsing
              ? null
              : () => _parseAndContinue(_textInputController.text),
          icon: _isParsing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: const Text('Continue to form'),
        ),
      ],
    );
  }

  Widget _buildVoiceInputStep() {
    final isListening = _voiceStatus == SpeechRecognitionStatus.listening;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Voice input',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Record, edit transcript if needed, then continue to the manual form.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isListening ? null : _startVoiceCapture,
              icon: const Icon(Icons.mic_none_outlined),
              label: const Text('Start'),
            ),
            OutlinedButton.icon(
              onPressed: isListening ? _stopVoiceCapture : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop'),
            ),
            TextButton.icon(
              onPressed: _voiceInputController.clear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Status: ${_voiceStatusLabel(_voiceStatus)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _voiceInputController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Voice transcript appears here (you can edit it).',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isParsing
              ? null
              : () => _parseAndContinue(_voiceInputController.text),
          icon: _isParsing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: const Text('Continue to form'),
        ),
      ],
    );
  }

  Widget _buildManualFormStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Expense details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (lei)',
              prefixText: 'lei ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final parsed = double.tryParse(value.replaceAll(',', '.').trim());
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid positive number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseCategory>(
            key: ValueKey<String>('category_${_category.name}'),
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
            items: ExpenseCategory.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(expenseCategoryLabel(c)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Vehicle>(
            key: ValueKey<String>('vehicle_${_selectedVehicle?.id ?? 'none'}'),
            initialValue: _selectedVehicle,
            decoration: const InputDecoration(
              labelText: 'Vehicle',
            ),
            items: widget.vehicles
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedVehicle = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mileageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mileage (km, optional)',
              helperText: 'If empty, the current vehicle mileage is used.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null;
              }
              final parsed = int.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid mileage';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDate(_selectedDate)),
                  const Icon(Icons.calendar_today_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: const Text('Save expense'),
          ),
        ],
      ),
    );
  }

  Future<void> _startVoiceCapture() async {
    await _speechService.startListening();
  }

  Future<void> _stopVoiceCapture() async {
    await _speechService.stopListening();

    if (!mounted) return;
    if (_voiceInputController.text.trim().isNotEmpty) return;

    final vehicleName = _selectedVehicle?.displayName ?? 'car';
    final fallback =
        'Am cheltuit 320 lei pe benzina pentru $vehicleName la 186000 km azi';

    _voiceInputController.text = fallback;
    _voiceInputController.selection = TextSelection.fromPosition(
      TextPosition(offset: fallback.length),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added a demo voice transcript.'),
      ),
    );
  }

  Future<void> _parseAndContinue(String rawInput) async {
    final normalized = rawInput.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide input first.')),
      );
      return;
    }

    setState(() {
      _isParsing = true;
    });

    try {
      final intent = await _nlpAnalyzer.analyze(normalized);
      if (!mounted) return;

      _applyParsedIntent(intent, normalized);

      setState(() {
        _step = ExpenseWizardStep.manualForm;
      });

      final lowConfidence = (intent.confidence ?? 0) < 0.5;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lowConfidence
                ? 'Could not parse all details. Please review and complete the form.'
                : 'Details parsed. Review and complete the form.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      if (_descriptionController.text.trim().isEmpty) {
        _descriptionController.text = normalized;
      }

      setState(() {
        _step = ExpenseWizardStep.manualForm;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Parsing failed. We opened the manual form with your description.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  void _applyParsedIntent(ParsedExpenseIntent intent, String rawInput) {
    if (intent.amount != null) {
      _amountController.text = _formatAmount(intent.amount!);
    }

    if (intent.category != null) {
      _category = intent.category!;
    }

    if (intent.mileage != null) {
      _mileageController.text = intent.mileage.toString();
    }

    if (intent.date != null) {
      final date = intent.date!;
      _selectedDate = DateTime(date.year, date.month, date.day);
    }

    final parsedVehicleText = intent.vehicleDisplayName?.toLowerCase().trim();
    if (parsedVehicleText != null && parsedVehicleText.isNotEmpty) {
      for (final vehicle in widget.vehicles) {
        final displayName = vehicle.displayName.toLowerCase();
        final brand = vehicle.brand.toLowerCase();
        final model = vehicle.model.toLowerCase();

        if (displayName.contains(parsedVehicleText) ||
            parsedVehicleText.contains(displayName) ||
            parsedVehicleText.contains(brand) ||
            parsedVehicleText.contains(model)) {
          _selectedVehicle = vehicle;
          break;
        }
      }
    }

    _descriptionController.text = intent.description?.trim().isNotEmpty == true
        ? intent.description!.trim()
        : rawInput;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (result != null) {
      setState(() => _selectedDate = result);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle.')),
      );
      return;
    }

    final amount = double.parse(
      _amountController.text.replaceAll(',', '.').trim(),
    );

    final mileage = _mileageController.text.trim().isEmpty
        ? _selectedVehicle!.mileage
        : int.parse(_mileageController.text.trim());

    final newExpense = CarExpense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: _category,
      date: _selectedDate,
      description: _descriptionController.text.isEmpty
          ? 'Car expense'
          : _descriptionController.text,
      mileage: mileage,
      vehicleId: _selectedVehicle!.id,
    );

    _allowPop = true;
    Navigator.of(context).pop(newExpense);
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasAnyInput()) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have entered expense details. If you leave now, your input will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  bool _hasAnyInput() {
    if (_textInputController.text.trim().isNotEmpty) return true;
    if (_voiceInputController.text.trim().isNotEmpty) return true;
    if (_amountController.text.trim().isNotEmpty) return true;
    if (_descriptionController.text.trim().isNotEmpty) return true;
    if (_mileageController.text.trim().isNotEmpty) return true;

    if (_category != ExpenseCategory.fuel) return true;
    if (_selectedVehicle?.id != _initialVehicleId) return true;

    final currentDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (currentDate != _initialDate) return true;

    return false;
  }

  ExpenseWizardStep _stepForMode(ExpenseInputMode mode) {
    switch (mode) {
      case ExpenseInputMode.voice:
        return ExpenseWizardStep.voiceInput;
      case ExpenseInputMode.text:
        return ExpenseWizardStep.textInput;
      case ExpenseInputMode.manual:
        return ExpenseWizardStep.manualForm;
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _voiceStatusLabel(SpeechRecognitionStatus status) {
    switch (status) {
      case SpeechRecognitionStatus.idle:
        return 'Idle';
      case SpeechRecognitionStatus.listening:
        return 'Listening';
      case SpeechRecognitionStatus.processing:
        return 'Processing';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
