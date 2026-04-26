import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/spark_top_bar.dart';
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
    required this.preferredCurrency,
    this.initialExpense,
  });

  final List<Vehicle> vehicles;
  final ExpenseEntryMode initialMode;
  final ExpenseCurrency preferredCurrency;
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

  StreamSubscription<SpeechRecognitionResult>? _speechResultSubscription;

  late ExpenseWizardStep _step;

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
        appBar: SparkTopBar(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dividerColor = colorScheme.outlineVariant.withAlpha(120);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Smart input', style: theme.textTheme.titleMedium),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _smartInputController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText:
                              'Type here, speak with mic, or capture a receipt photo.',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (_lastSmartSource != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Source: $_lastSmartSource',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSmartActionButton(
                    tooltip: 'Voice controls',
                    icon: LucideIcons.mic,
                    onPressed: _isParsing ? null : _openVoiceControlsSheet,
                  ),
                  const SizedBox(width: 8),
                  _buildSmartActionButton(
                    tooltip: 'Take photo and extract text',
                    icon: LucideIcons.camera,
                    onPressed: _isParsing ? null : _runPhotoOcrDemo,
                  ),
                  const SizedBox(width: 8),
                  _buildSmartActionButton(
                    tooltip: 'Clear',
                    icon: LucideIcons.x,
                    onPressed: _isParsing
                        ? null
                        : () {
                            _smartInputController.clear();
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
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
                        : const Icon(LucideIcons.wand2),
                    label: const Text('Continue'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: CircleBorder(side: BorderSide(color: theme.dividerColor)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        padding: const EdgeInsets.all(12),
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }

  Widget _buildManualFormStep() {
    final selectedUnit = _selectedVehicle?.distanceUnit ?? DistanceUnit.km;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Amount (${expenseCurrencyCode(widget.preferredCurrency)})',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final parsed = double.tryParse(
                      value.replaceAll(',', '.').trim(),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
              ),
            ],
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
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mileageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  'Mileage (${distanceUnitShortLabel(selectedUnit)}, optional)',
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
                  const Icon(LucideIcons.calendar),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(LucideIcons.check),
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

    final fallback =
        'motorina 320 lei pentru passat, pe la 186000 km';

    _smartInputController.text = fallback;
    _smartInputController.selection = TextSelection.fromPosition(
      TextPosition(offset: fallback.length),
    );
    _lastSmartSource = 'Voice';
  }

  Future<void> _resetVoiceCapture() async {
    await _speechService.cancel();
    if (!mounted) return;

    _smartInputController.clear();
    setState(() {
      _lastSmartSource = null;
    });
  }

  Future<void> _openVoiceControlsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SparkVoiceRecordingSheet(
          speechService: _speechService,
          transcriptController: _smartInputController,
          onStart: _startVoiceCapture,
          onStop: _stopVoiceCapture,
          onReset: _resetVoiceCapture,
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

      const fallback =
          'Factura service Porsche Cayenne, total 4800 MDL, km 146200, '
          'manopera 2200 mdl, placute frana fata 1400 mdl, discuri fata 900 mdl, '
          'diagnoza 300 mdl, schimb ulei + filtru, service reparatie';

      final raw = result.rawText.trim().isEmpty
          ? fallback
          : result.rawText.trim();
      _smartInputController.text = raw;
      _smartInputController.selection = TextSelection.fromPosition(
        TextPosition(offset: raw.length),
      );
      _lastSmartSource = 'Photo/OCR';
    } catch (_) {
      // Keep flow silent: camera/OCR failures should not trigger popups.
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
    } catch (_) {
      if (!mounted) return;

      if (_descriptionController.text.trim().isEmpty) {
        _descriptionController.text = normalized;
      }

      setState(() {
        _step = ExpenseWizardStep.manualForm;
        _lastSmartSource = sourceLabel;
      });
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
      currency: widget.preferredCurrency,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SparkVoiceRecordingSheet extends StatefulWidget {
  const _SparkVoiceRecordingSheet({
    required this.speechService,
    required this.transcriptController,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  final SpeechRecognitionService speechService;
  final TextEditingController transcriptController;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;
  final Future<void> Function() onReset;

  @override
  State<_SparkVoiceRecordingSheet> createState() =>
      _SparkVoiceRecordingSheetState();
}

class _SparkVoiceRecordingSheetState extends State<_SparkVoiceRecordingSheet> {
  StreamSubscription<SpeechRecognitionStatus>? _statusSubscription;
  Timer? _ticker;
  SpeechRecognitionStatus _status = SpeechRecognitionStatus.idle;
  Duration _elapsed = Duration.zero;
  double _level = 0;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _status = widget.speechService.status;
    _statusSubscription = widget.speechService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _status = status;
        if (status == SpeechRecognitionStatus.listening) {
          _hasStarted = true;
        }
      });
    });

    _ticker = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() {
        if (_status == SpeechRecognitionStatus.listening) {
          _elapsed += const Duration(milliseconds: 120);
          final phase = (_elapsed.inMilliseconds % 900) / 900;
          _level = phase < 0.5
              ? (0.2 + phase * 1.6)
              : (0.2 + (1 - phase) * 1.6);
        } else {
          _level *= 0.75;
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_status == SpeechRecognitionStatus.processing) return;

    if (_status == SpeechRecognitionStatus.listening) {
      await widget.onStop();
      return;
    }

    await widget.onStart();
    if (!mounted) return;
    setState(() {
      _hasStarted = true;
    });
  }

  Future<void> _handleDiscard() async {
    await widget.speechService.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleSave() async {
    if (_status == SpeechRecognitionStatus.listening) {
      await widget.onStop();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleReset() async {
    await widget.onReset();
    if (!mounted) return;
    setState(() {
      _hasStarted = false;
      _elapsed = Duration.zero;
      _level = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSave =
        _hasStarted && _status == SpeechRecognitionStatus.idle;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _SheetCircleButton(
                  icon: LucideIcons.x,
                  onPressed: _handleDiscard,
                  enabled: _status != SpeechRecognitionStatus.processing,
                ),
                const Spacer(),
                _SheetCircleButton(
                  icon: LucideIcons.check,
                  onPressed: _handleSave,
                  enabled: canSave,
                ),
              ],
            ),
            const Spacer(),
            Text(
              _formatDuration(_elapsed),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _VoiceWaveformMeter(
              level: _level,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Center(
              child: _SheetCircleButton(
                icon: _status == SpeechRecognitionStatus.listening
                    ? LucideIcons.pause
                    : LucideIcons.play,
                onPressed: _handlePrimaryAction,
                enabled: _status != SpeechRecognitionStatus.processing,
                size: 64,
                iconSize: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _statusLabel(_status),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _status == SpeechRecognitionStatus.processing
                  ? null
                  : _handleReset,
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: const Text('Reset'),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.transcriptController,
              builder: (context, value, _) {
                final text = value.text.trim();
                return Text(
                  text.isEmpty
                      ? 'Transcript will appear in the smart input box.'
                      : text,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _statusLabel(SpeechRecognitionStatus status) {
    switch (status) {
      case SpeechRecognitionStatus.idle:
        return _hasStarted ? 'Ready to save' : 'Ready';
      case SpeechRecognitionStatus.listening:
        return 'Recording...';
      case SpeechRecognitionStatus.processing:
        return 'Processing...';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SheetCircleButton extends StatelessWidget {
  const _SheetCircleButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.size = 48,
    this.iconSize = 22,
  });

  final IconData icon;
  final Future<void> Function() onPressed;
  final bool enabled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: enabled ? () => unawaited(onPressed()) : null,
        icon: Icon(icon, size: iconSize),
        style: IconButton.styleFrom(
          shape: CircleBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          disabledForegroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _VoiceWaveformMeter extends StatelessWidget {
  const _VoiceWaveformMeter({required this.level, required this.color});

  final double level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: CustomPaint(
        painter: _VoiceWaveformPainter(level: level, color: color),
      ),
    );
  }
}

class _VoiceWaveformPainter extends CustomPainter {
  const _VoiceWaveformPainter({required this.level, required this.color});

  final double level;
  final Color color;

  static const List<double> _pattern = [
    0.2,
    0.35,
    0.5,
    0.3,
    0.6,
    0.4,
    0.75,
    0.45,
    0.7,
    0.4,
    0.85,
    0.5,
    0.7,
    0.45,
    0.8,
    0.4,
    0.6,
    0.35,
    0.5,
    0.3,
    0.4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final midY = size.height / 2;
    final maxAmp = size.height / 2;
    final clamped = level.clamp(0.0, 1.0);
    final step = size.width / (_pattern.length - 1);

    for (int i = 0; i < _pattern.length; i++) {
      final amp = maxAmp * clamped * _pattern[i];
      final x = step * i;
      canvas.drawLine(Offset(x, midY - amp), Offset(x, midY + amp), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
