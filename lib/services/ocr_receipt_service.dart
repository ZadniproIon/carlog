import 'dart:typed_data';

class OcrLineItem {
  const OcrLineItem({required this.text, this.amount});

  final String text;
  final double? amount;
}

class OcrReceiptResult {
  const OcrReceiptResult({
    required this.rawText,
    required this.items,
    this.total,
    this.currency,
    this.merchant,
  });

  final String rawText;
  final List<OcrLineItem> items;
  final double? total;
  final String? currency;
  final String? merchant;
}

class OcrReceiptService {
  const OcrReceiptService();

  Future<OcrReceiptResult> processReceipt(Uint8List imageBytes) async {
    final rawText = '';

    return OcrReceiptResult(
      rawText: rawText,
      items: const [],
      total: null,
      currency: null,
      merchant: null,
    );
  }
}

