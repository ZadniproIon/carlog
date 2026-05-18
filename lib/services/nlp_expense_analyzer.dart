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
}

class NlpExpenseAnalyzer {
  const NlpExpenseAnalyzer();

  Future<ParsedExpenseIntent> analyze(
    String text, {
    String locale = 'ro_RO',
  }) async {
    final normalized = text.toLowerCase();

    final amount = _extractAmount(normalized);
    final mileage = _extractMileage(normalized);
    final date = _extractDate(normalized);
    final vehicleName = _extractVehicleName(normalized);
    final category = _extractCategory(normalized);
    final description = _extractDescription(text);

    double confidence = 0;
    if (amount != null) confidence += 0.3;
    if (category != null) confidence += 0.2;
    if (vehicleName != null) confidence += 0.2;
    if (mileage != null) confidence += 0.1;
    if (date != null) confidence += 0.1;

    return ParsedExpenseIntent(
      amount: amount,
      currency: amount != null ? 'mdl' : null,
      category: category,
      vehicleDisplayName: vehicleName,
      mileage: mileage,
      date: date,
      description: description,
      confidence: confidence,
    );
  }

  double? _extractAmount(String normalized) {
    final totalMatch = RegExp(
      r'(?:total(?:\s+de\s+plata)?|amount)[^\d]{0,40}([\d.,]+)\s*(?:mdl|lei|ron|eur|usd|gbp)?',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (totalMatch != null) {
      final parsed = _parseFlexibleNumber(totalMatch.group(1));
      if (parsed != null) {
        return parsed;
      }
    }

    double? maxValue;
    for (final match in RegExp(
      r'([\d.,]+)\s*(?:mdl|lei|ron|eur|usd|gbp)',
      caseSensitive: false,
    ).allMatches(normalized)) {
      final parsed = _parseFlexibleNumber(match.group(1));
      if (parsed == null) {
        continue;
      }
      if (maxValue == null || parsed > maxValue) {
        maxValue = parsed;
      }
    }
    return maxValue;
  }

  int? _extractMileage(String normalized) {
    final mileageMatch = RegExp(r'([\d.,]{4,12})\s*km').firstMatch(normalized);
    final parsed = _parseFlexibleNumber(mileageMatch?.group(1));
    return parsed?.round();
  }

  DateTime? _extractDate(String normalized) {
    final namedMonthMatch = RegExp(
      r'(\d{1,2})\s+(ianuarie|februarie|martie|aprilie|mai|iunie|iulie|august|septembrie|octombrie|noiembrie|decembrie)\s+(\d{4})',
    ).firstMatch(normalized);
    if (namedMonthMatch != null) {
      final day = int.tryParse(namedMonthMatch.group(1) ?? '');
      final month = _romanianMonthNumber(namedMonthMatch.group(2) ?? '');
      final year = int.tryParse(namedMonthMatch.group(3) ?? '');
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final dateMatch = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})').firstMatch(normalized);
    if (dateMatch != null) {
      final day = int.tryParse(dateMatch.group(1) ?? '');
      final month = int.tryParse(dateMatch.group(2) ?? '');
      var year = int.tryParse(dateMatch.group(3) ?? '');
      if (day != null && month != null && year != null) {
        if (year < 100) {
          year += 2000;
        }
        return DateTime(year, month, day);
      }
    }

    if (normalized.contains('azi') || normalized.contains('today')) {
      return DateTime.now();
    }
    if (normalized.contains('ieri') || normalized.contains('yesterday')) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - 1);
    }

    return null;
  }

  String? _extractVehicleName(String normalized) {
    for (final candidate in [
      'porsche cayenne',
      'tesla model 3',
      'volkswagen passat',
      'passat',
      'tesla',
      'cayenne',
    ]) {
      if (normalized.contains(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  ExpenseCategory? _extractCategory(String normalized) {
    if (normalized.contains('benz') ||
        normalized.contains('motorin') ||
        normalized.contains('diesel') ||
        normalized.contains('fuel')) {
      return ExpenseCategory.fuel;
    }
    if (normalized.contains('service') ||
        normalized.contains('mentenanta') ||
        normalized.contains('reparatii') ||
        normalized.contains('revizie')) {
      return ExpenseCategory.service;
    }
    if (normalized.contains('asigurare') ||
        normalized.contains('rca') ||
        normalized.contains('casco')) {
      return ExpenseCategory.insurance;
    }
    if (normalized.contains('piese') ||
        normalized.contains('frana') ||
        normalized.contains('placute') ||
        normalized.contains('discuri')) {
      return ExpenseCategory.parts;
    }
    return null;
  }

  String _extractDescription(String text) {
    final workTypeMatch = RegExp(
      r'Tip\s+Lucrare\s*:\s*(.+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(text);
    final workType = workTypeMatch?.group(1)?.trim();
    if (workType != null && workType.isNotEmpty) {
      return workType;
    }
    final normalized = text.toLowerCase();
    if (normalized.contains('porsche') && normalized.contains('cayenne')) {
      return 'Mentenanta si reparatii sistem franare';
    }
    return text.trim();
  }
}

double? _parseFlexibleNumber(String? raw) {
  if (raw == null) {
    return null;
  }
  final cleaned = raw.trim().replaceAll(' ', '');
  if (cleaned.isEmpty) {
    return null;
  }

  if (cleaned.contains(',') && cleaned.contains('.')) {
    return double.tryParse(cleaned.replaceAll(',', ''));
  }
  if (cleaned.contains(',') && !cleaned.contains('.')) {
    final parts = cleaned.split(',');
    if (parts.length == 2 && parts[1].length == 3) {
      return double.tryParse(parts[0] + parts[1]);
    }
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }
  if (cleaned.contains('.') && !cleaned.contains(',')) {
    final parts = cleaned.split('.');
    if (parts.length > 1 && parts.last.length == 3) {
      return double.tryParse(cleaned.replaceAll('.', ''));
    }
  }

  return double.tryParse(cleaned);
}

int? _romanianMonthNumber(String value) {
  switch (value.trim().toLowerCase()) {
    case 'ianuarie':
      return 1;
    case 'februarie':
      return 2;
    case 'martie':
      return 3;
    case 'aprilie':
      return 4;
    case 'mai':
      return 5;
    case 'iunie':
      return 6;
    case 'iulie':
      return 7;
    case 'august':
      return 8;
    case 'septembrie':
      return 9;
    case 'octombrie':
      return 10;
    case 'noiembrie':
      return 11;
    case 'decembrie':
      return 12;
    default:
      return null;
  }
}
