import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/nlp_expense_analyzer.dart';
import '../services/ocr_receipt_service.dart';
import '../services/speech_recognition_service.dart';

enum ExpenseEntryMode { smart, manual }

enum ExpenseWizardStep { smartInput, manualForm }

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.vehicles,
    required this.initialMode,
    this.initialExpense,
  });

  final List<Vehicle> vehicles;
  final ExpenseEntryMode initialMode;
  final CarExpense? initialExpense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _smartInputController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();

  final _nlpAnalyzer = const NlpExpenseAnalyzer();
  final _speechService = SpeechRecognitionService();
  final _ocrService = const OcrReceiptService();
  final _imagePicker = ImagePicker();

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
  String? _lastSmartSource;

  @override
  void initState() {
    super.initState();

    _step = widget.initialExpense != null
        ? ExpenseWizardStep.manualForm
        : widget.initialMode == ExpenseEntryMode.manual
        ? ExpenseWizardStep.manualForm
        : ExpenseWizardStep.smartInput;

    if (widget.vehicles.isNotEmpty) {
      _selectedVehicle = widget.vehicles.first;
    }

    if (widget.initialExpense != null) {
      final expense = widget.initialExpense!;
      _amountController.text = _formatAmount(expense.amount);
      _descriptionController.text = expense.description;
      _mileageController.text = expense.mileage.toString();
      _category = expense.category;
      _selectedDate = expense.date;
      _selectedVehicle = widget.vehicles
          .where((vehicle) => vehicle.id == expense.vehicleId)
          .firstOrNull;
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
      _smartInputController.text = result.text.trim();
      _smartInputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _smartInputController.text.length),
      );
      _lastSmartSource = 'Voice';
    });
  }

  @override
  void dispose() {
    _speechStatusSubscription?.cancel();
    _speechResultSubscription?.cancel();
    unawaited(_speechService.dispose());

    _smartInputController.dispose();
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
          title: Text(
            widget.initialExpense == null ? 'Add expense' : 'Edit expense',
          ),
        ),
        body: SafeArea(child: _buildCurrentStep()),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case ExpenseWizardStep.smartInput:
        return _buildSmartInputStep();
      case ExpenseWizardStep.manualForm:
        return _buildManualFormStep();
    }
  }

  Widget _buildSmartInputStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Smart input', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Use one box for text/voice/OCR. We always open review before save.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_lastSmartSource != null) ...[
          const SizedBox(height: 10),
          Chip(
            avatar: const Icon(Icons.auto_awesome, size: 16),
            label: Text('Last source: $_lastSmartSource'),
          ),
        ],
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Smart input box',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Voice controls',
                      onPressed: _isParsing ? null : _openVoiceControlsSheet,
                      icon: const Icon(Icons.mic),
                    ),
                    IconButton(
                      tooltip: 'Take photo and extract text',
                      onPressed: _isParsing ? null : _runPhotoOcrDemo,
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: _isParsing
                          ? null
                          : () {
                              _smartInputController.clear();
                            },
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ),
                Text(
                  'Voice status: ${_voiceStatusLabel(_voiceStatus)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _smartInputController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'Type here, speak with mic, or capture a receipt photo.',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isParsing
                        ? null
                        : () => _parseAndContinue(
                            _smartInputController.text,
                            sourceLabel: _lastSmartSource ?? 'Smart',
                          ),
                    icon: _isParsing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
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
            decoration: const InputDecoration(labelText: 'Category'),
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
            decoration: const InputDecoration(labelText: 'Vehicle'),
            items: widget.vehicles
                .map(
                  (v) => DropdownMenuItem(value: v, child: Text(v.displayName)),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedVehicle = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
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
              decoration: const InputDecoration(labelText: 'Date'),
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
            label: Text(
              widget.initialExpense == null ? 'Save expense' : 'Update expense',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startVoiceCapture() async {
    await _speechService.startListening();
    _lastSmartSource = 'Voice';
  }

  Future<void> _stopVoiceCapture() async {
    await _speechService.stopListening();

    if (!mounted) return;
    if (_smartInputController.text.trim().isNotEmpty) return;

    final vehicleName = _selectedVehicle?.displayName ?? 'car';
    final fallback =
        'Am cheltuit 320 lei pe benzina pentru $vehicleName la 186000 km azi';

    _smartInputController.text = fallback;
    _smartInputController.selection = TextSelection.fromPosition(
      TextPosition(offset: fallback.length),
    );
    _lastSmartSource = 'Voice';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added a demo voice transcript.')),
    );
  }

  Future<void> _resetVoiceCapture() async {
    await _speechService.cancel();
    if (!mounted) return;

    _smartInputController.clear();
    setState(() {
      _lastSmartSource = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voice input reset.')));
  }

  Future<void> _openVoiceControlsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              6,
              16,
              16 + MediaQuery.of(sheetContext).viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice input',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start recording, pause/end, or reset.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                StreamBuilder<SpeechRecognitionStatus>(
                  stream: _speechService.statusStream,
                  initialData: _voiceStatus,
                  builder: (context, snapshot) {
                    final status =
                        snapshot.data ?? SpeechRecognitionStatus.idle;
                    final isListening =
                        status == SpeechRecognitionStatus.listening;
                    final isProcessing =
                        status == SpeechRecognitionStatus.processing;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _VoiceControlButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Start',
                          enabled: !isListening && !isProcessing,
                          onPressed: _startVoiceCapture,
                        ),
                        _VoiceControlButton(
                          icon: Icons.pause_circle_outline,
                          label: 'Pause/End',
                          enabled: isListening,
                          onPressed: () async {
                            await _stopVoiceCapture();
                            if (!sheetContext.mounted) return;
                            await Navigator.of(sheetContext).maybePop();
                          },
                        ),
                        _VoiceControlButton(
                          icon: Icons.restart_alt_rounded,
                          label: 'Reset',
                          enabled: !isProcessing,
                          onPressed: _resetVoiceCapture,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _smartInputController,
                  builder: (context, value, _) {
                    final text = value.text.trim();
                    return Text(
                      text.isEmpty
                          ? 'Transcript will appear in the smart input box.'
                          : text,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runPhotoOcrDemo() async {
    setState(() {
      _isParsing = true;
    });

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (!mounted || image == null) {
        return;
      }

      final imageBytes = await image.readAsBytes();
      final result = await _ocrService.processReceipt(
        imageBytes.isEmpty ? Uint8List(0) : imageBytes,
      );
      if (!mounted) {
        return;
      }

      final fallback = _selectedVehicle == null
          ? 'Bon fiscal: total 260 lei, 185500 km, alimentare azi'
          : 'Bon fiscal: total 260 lei, ${_selectedVehicle!.displayName}, '
                '185500 km, alimentare azi';

      final raw = result.rawText.trim().isEmpty
          ? fallback
          : result.rawText.trim();
      _smartInputController.text = raw;
      _smartInputController.selection = TextSelection.fromPosition(
        TextPosition(offset: raw.length),
      );
      _lastSmartSource = 'Photo/OCR';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.rawText.trim().isEmpty
                ? 'Photo captured. Added demo OCR text.'
                : 'Photo captured and text extracted.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture photo. Please check camera access.'),
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

  Future<void> _parseAndContinue(
    String rawInput, {
    required String sourceLabel,
  }) async {
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
        _lastSmartSource = sourceLabel;
      });

      final lowConfidence = (intent.confidence ?? 0) < 0.5;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lowConfidence
                ? 'Could not parse all details. Please review and complete the form.'
                : 'Details parsed from $sourceLabel. Review and complete the form.',
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
        _lastSmartSource = sourceLabel;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vehicle.')));
      return;
    }

    final amount = double.parse(
      _amountController.text.replaceAll(',', '.').trim(),
    );

    final mileage = _mileageController.text.trim().isEmpty
        ? _selectedVehicle!.mileage
        : int.parse(_mileageController.text.trim());

    final newExpense = CarExpense(
      id:
          widget.initialExpense?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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
    if (_smartInputController.text.trim().isNotEmpty) return true;
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

class _VoiceControlButton extends StatelessWidget {
  const _VoiceControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: enabled
              ? () {
                  unawaited(onPressed());
                }
              : null,
          icon: Icon(icon),
          tooltip: label,
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
