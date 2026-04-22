import 'dart:async';
import 'dart:typed_data';

enum SpeechRecognitionStatus { idle, listening, processing }

class SpeechRecognitionResult {
  const SpeechRecognitionResult({
    required this.text,
    required this.isFinal,
    this.locale,
    this.confidence,
  });

  final String text;
  final bool isFinal;
  final String? locale;
  final double? confidence;
}

class SpeechRecognitionService {
  final _statusController =
      StreamController<SpeechRecognitionStatus>.broadcast();
  final _resultController =
      StreamController<SpeechRecognitionResult>.broadcast();

  SpeechRecognitionStatus _status = SpeechRecognitionStatus.idle;

  Stream<SpeechRecognitionStatus> get statusStream => _statusController.stream;

  Stream<SpeechRecognitionResult> get resultsStream => _resultController.stream;

  SpeechRecognitionStatus get status => _status;

  Future<void> startListening({String locale = 'ro_RO'}) async {
    if (_status == SpeechRecognitionStatus.listening) return;
    _updateStatus(SpeechRecognitionStatus.listening);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _resultController.add(
      SpeechRecognitionResult(
        text: '',
        isFinal: false,
        locale: locale,
        confidence: null,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_status != SpeechRecognitionStatus.listening) return;
    _updateStatus(SpeechRecognitionStatus.processing);

    await Future<void>.delayed(const Duration(milliseconds: 400));
    _updateStatus(SpeechRecognitionStatus.idle);
  }

  Future<void> cancel() async {
    _updateStatus(SpeechRecognitionStatus.idle);
  }

  Future<void> processOfflineAudio(
    Uint8List audioBytes, {
    String locale = 'ro_RO',
  }) async {
    _updateStatus(SpeechRecognitionStatus.processing);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _resultController.add(
      SpeechRecognitionResult(
        text: '',
        isFinal: true,
        locale: locale,
        confidence: null,
      ),
    );
    _updateStatus(SpeechRecognitionStatus.idle);
  }

  void _updateStatus(SpeechRecognitionStatus value) {
    _status = value;
    _statusController.add(value);
  }

  Future<void> dispose() async {
    await _statusController.close();
    await _resultController.close();
  }
}

