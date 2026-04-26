import '../models.dart';

class ParsedExpenseIntent {
  const ParsedExpenseIntent({
    this.amount,
    this.currency,
    this.category,
    this.vehicleDisplayName,
    this.mileage,
    this.date,
    this.description,
    this.confidence,
  });

  final double? amount;
  final String? currency;
  final ExpenseCategory? category;
  final String? vehicleDisplayName;
  final int? mileage;
  final DateTime? date;
  final String? description;
  final double? confidence;

  ParsedExpenseIntent copyWith({
    double? amount,
    String? currency,
    ExpenseCategory? category,
    String? vehicleDisplayName,
    int? mileage,
    DateTime? date,
    String? description,
    double? confidence,
  }) {
    return ParsedExpenseIntent(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      vehicleDisplayName: vehicleDisplayName ?? this.vehicleDisplayName,
      mileage: mileage ?? this.mileage,
      date: date ?? this.date,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
    );
  }
}

class NlpExpenseAnalyzer {
  const NlpExpenseAnalyzer();

  Future<ParsedExpenseIntent> analyze(
    String text, {
    String locale = 'ro_RO',
  }) async {
    final normalized = text.toLowerCase();

    double? amount;
    String? currency;
    final totalMatch = RegExp(
      r'(?:total|suma totala|sumă totală|amount)\s*[:\-]?\s*(\d+[.,]?\d*)\s*(lei|ron|eur|euro|usd|gbp|mdl)?',
      caseSensitive: false,
    ).firstMatch(normalized);
    final currencyMatch = RegExp(
      r'(\d+[.,]?\d*)\s*(lei|ron|eur|euro|usd|gbp|mdl)?',
      caseSensitive: false,
    ).firstMatch(normalized);
    final effectiveAmountMatch = totalMatch ?? currencyMatch;
    if (effectiveAmountMatch != null) {
      final raw = effectiveAmountMatch.group(1)?.replaceAll(',', '.');
      final parsed = double.tryParse(raw ?? '');
      if (parsed != null) {
        amount = parsed;
        currency = effectiveAmountMatch.group(2) ?? 'lei';
      }
    }

    ExpenseCategory? category;
    if (normalized.contains('benz') ||
        normalized.contains('motorin') ||
        normalized.contains('diesel') ||
        normalized.contains('fuel')) {
      category = ExpenseCategory.fuel;
    } else if (normalized.contains('service') ||
        normalized.contains('revizie') ||
        normalized.contains('garaj')) {
      category = ExpenseCategory.service;
    } else if (normalized.contains('asigurare') ||
        normalized.contains('rca') ||
        normalized.contains('casco')) {
      category = ExpenseCategory.insurance;
    } else if (normalized.contains('piese') ||
        normalized.contains('fran') ||
        normalized.contains('placute') ||
        normalized.contains('discuri')) {
      category = ExpenseCategory.parts;
    }

    final mileageMatch = RegExp(
      r'(\d{4,6})\s*km',
      caseSensitive: false,
    ).firstMatch(normalized);
    int? mileage;
    if (mileageMatch != null) {
      mileage = int.tryParse(mileageMatch.group(1) ?? '');
    }

    String? vehicleName;
    for (final candidate in [
      'golf',
      'passat',
      'duster',
      'cayenne',
      'tesla',
      'model 3',
    ]) {
      if (normalized.contains(candidate)) {
        vehicleName = candidate;
        break;
      }
    }

    DateTime? date;
    if (normalized.contains('azi') || normalized.contains('today')) {
      date = DateTime.now();
    } else if (normalized.contains('ieri') ||
        normalized.contains('yesterday')) {
      final now = DateTime.now();
      date = DateTime(now.year, now.month, now.day - 1);
    } else {
      final dateMatch = RegExp(
        r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})',
      ).firstMatch(normalized);
      if (dateMatch != null) {
        final day = int.tryParse(dateMatch.group(1) ?? '');
        final month = int.tryParse(dateMatch.group(2) ?? '');
        var year = int.tryParse(dateMatch.group(3) ?? '');
        if (day != null && month != null && year != null) {
          if (year < 100) {
            year += 2000;
          }
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            date = DateTime(year, month, day);
          }
        }
      }
    }

    double confidence = 0;
    if (amount != null) confidence += 0.3;
    if (category != null) confidence += 0.2;
    if (vehicleName != null) confidence += 0.2;
    if (mileage != null) confidence += 0.1;
    if (date != null) confidence += 0.1;
    if (confidence > 1) confidence = 1;

    return ParsedExpenseIntent(
      amount: amount,
      currency: currency,
      category: category,
      vehicleDisplayName: vehicleName,
      mileage: mileage,
      date: date,
      description: text,
      confidence: confidence,
    );
  }
}
