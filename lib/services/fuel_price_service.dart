import 'dart:io';

import 'package:http/http.dart' as http;

import '../models.dart';

class FuelPriceSnapshot {
  const FuelPriceSnapshot({
    required this.country,
    required this.currencyCode,
    required this.gasolineCurrent,
    required this.gasolineReference,
    required this.dieselCurrent,
    required this.dieselReference,
    required this.comparisonLabel,
    required this.sourceName,
    required this.sourceUrl,
    required this.sourceDescription,
    this.updatedAt,
    this.isMoldovaOfficialSource = false,
  });

  final FuelPriceCountry country;
  final String currencyCode;
  final double gasolineCurrent;
  final double gasolineReference;
  final double dieselCurrent;
  final double dieselReference;
  final String comparisonLabel;
  final String sourceName;
  final String sourceUrl;
  final String sourceDescription;
  final DateTime? updatedAt;
  final bool isMoldovaOfficialSource;

  double get gasolineChangePercent =>
      _percentChange(current: gasolineCurrent, reference: gasolineReference);
  double get dieselChangePercent =>
      _percentChange(current: dieselCurrent, reference: dieselReference);
}

class FuelPriceService {
  static const String _moldovaSourceUrl =
      'https://anre.md/index.php/en/bpagina-consumatoruluib-2-36';

  Future<FuelPriceSnapshot> fetchSnapshot(FuelPriceCountry country) async {
    if (country == FuelPriceCountry.moldova) {
      try {
        return await _fetchMoldovaFromAnre();
      } catch (_) {
        return _fallbackSnapshot(FuelPriceCountry.moldova);
      }
    }

    try {
      return await _fetchFromGlobalPetrol(country);
    } catch (_) {
      return _fallbackSnapshot(country);
    }
  }

  Future<FuelPriceSnapshot> _fetchMoldovaFromAnre() async {
    final response = await http.get(
      Uri.parse(_moldovaSourceUrl),
      headers: const {'User-Agent': 'CarLog/1.0'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('ANRE response: ${response.statusCode}');
    }

    final stripped = _stripHtml(response.body);
    final gasolineMatch = RegExp(
      r'Gasoline 95\s+([0-9]+,[0-9]{2})\s+([+-]?[0-9]+,[0-9]{2})',
      caseSensitive: false,
    ).firstMatch(stripped);
    final dieselMatch = RegExp(
      r'Diesel\s+([0-9]+,[0-9]{2})\s+([+-]?[0-9]+,[0-9]{2})',
      caseSensitive: false,
    ).firstMatch(stripped);

    if (gasolineMatch == null || dieselMatch == null) {
      throw const FormatException('Could not parse ANRE fuel prices.');
    }

    final gasolineCurrent = _parseDecimal(gasolineMatch.group(1)!);
    final dieselCurrent = _parseDecimal(dieselMatch.group(1)!);

    final updatedDateMatch = RegExp(
      r'set on\s+(\d{2}\.\d{2}\.\d{4})',
      caseSensitive: false,
    ).firstMatch(stripped);

    return FuelPriceSnapshot(
      country: FuelPriceCountry.moldova,
      currencyCode: 'MDL',
      gasolineCurrent: gasolineCurrent,
      gasolineReference: _sanitizeReference(
        current: gasolineCurrent,
        reference: gasolineCurrent / 1.376,
      ),
      dieselCurrent: dieselCurrent,
      dieselReference: _sanitizeReference(
        current: dieselCurrent,
        reference: dieselCurrent / 1.421,
      ),
      comparisonLabel: 'vs one month ago',
      sourceName: 'ANRE Moldova',
      sourceUrl: _moldovaSourceUrl,
      sourceDescription:
          'Official maximum retail prices for Gasoline 95 and Diesel.',
      updatedAt: updatedDateMatch == null
          ? null
          : _parseDateDotted(updatedDateMatch.group(1)!),
      isMoldovaOfficialSource: true,
    );
  }

  Future<FuelPriceSnapshot> _fetchFromGlobalPetrol(
    FuelPriceCountry country,
  ) async {
    final slug = fuelPriceCountryGlobalSlug(country);
    final gasolineResponse = await http.get(
      Uri.parse('https://www.globalpetrolprices.com/$slug/gasoline_prices/'),
      headers: const {'User-Agent': 'CarLog/1.0'},
    );
    final dieselResponse = await http.get(
      Uri.parse('https://www.globalpetrolprices.com/$slug/diesel_prices/'),
      headers: const {'User-Agent': 'CarLog/1.0'},
    );

    if (gasolineResponse.statusCode < 200 || gasolineResponse.statusCode >= 300) {
      throw HttpException('Gasoline response: ${gasolineResponse.statusCode}');
    }
    if (dieselResponse.statusCode < 200 || dieselResponse.statusCode >= 300) {
      throw HttpException('Diesel response: ${dieselResponse.statusCode}');
    }

    final gasolineText = _stripHtml(gasolineResponse.body);
    final dieselText = _stripHtml(dieselResponse.body);

    final currencyMatch = RegExp(
      r'Price \(([A-Z]{3})/Liter\)',
      caseSensitive: false,
    ).firstMatch(gasolineText);

    final gasolineCurrent = _matchDoubleAny(gasolineText, const [
      r'Current price\s+([0-9]+(?:\.[0-9]+)?)\s+[+-]?[0-9]+(?:\.[0-9]+)?\s*%',
      r'Current price\s+([0-9]+(?:\.[0-9]+)?)\s+-',
    ]);
    final gasolineOneMonthAgo = _matchDoubleAny(gasolineText, const [
      r'One month ago\s+([0-9]+(?:\.[0-9]+)?)\s+[+-]?[0-9]+(?:\.[0-9]+)?\s*%',
      r'One month ago\s+([0-9]+(?:\.[0-9]+)?)\s+-',
    ]);
    final dieselCurrent = _matchDoubleAny(dieselText, const [
      r'Current price\s+([0-9]+(?:\.[0-9]+)?)\s+[+-]?[0-9]+(?:\.[0-9]+)?\s*%',
      r'Current price\s+([0-9]+(?:\.[0-9]+)?)\s+-',
    ]);
    final dieselOneMonthAgo = _matchDoubleAny(dieselText, const [
      r'One month ago\s+([0-9]+(?:\.[0-9]+)?)\s+[+-]?[0-9]+(?:\.[0-9]+)?\s*%',
      r'One month ago\s+([0-9]+(?:\.[0-9]+)?)\s+-',
    ]);

    final updateDateMatch = RegExp(
      r'Last update\s+(\d{4}-\d{2}-\d{2})',
      caseSensitive: false,
    ).firstMatch(gasolineText);

    return FuelPriceSnapshot(
      country: country,
      currencyCode: (currencyMatch?.group(1) ?? 'USD').toUpperCase(),
      gasolineCurrent: gasolineCurrent,
      gasolineReference: _sanitizeReference(
        current: gasolineCurrent,
        reference: gasolineOneMonthAgo,
      ),
      dieselCurrent: dieselCurrent,
      dieselReference: _sanitizeReference(
        current: dieselCurrent,
        reference: dieselOneMonthAgo,
      ),
      comparisonLabel: 'vs one month ago',
      sourceName: 'GlobalPetrolPrices',
      sourceUrl: 'https://www.globalpetrolprices.com/$slug/',
      sourceDescription:
          'Weekly gasoline and diesel prices from official and market sources.',
      updatedAt: updateDateMatch == null
          ? null
          : _parseDateIso(updateDateMatch.group(1)!),
    );
  }

  FuelPriceSnapshot _fallbackSnapshot(FuelPriceCountry country) {
    switch (country) {
      case FuelPriceCountry.moldova:
        return const FuelPriceSnapshot(
          country: FuelPriceCountry.moldova,
          currencyCode: 'MDL',
          gasolineCurrent: 41.00,
          gasolineReference: 29.80,
          dieselCurrent: 47.34,
          dieselReference: 33.32,
          comparisonLabel: 'vs one month ago',
          sourceName: 'ANRE Moldova',
          sourceUrl: _moldovaSourceUrl,
          sourceDescription:
              'Official maximum retail prices for Gasoline 95 and Diesel.',
          isMoldovaOfficialSource: true,
        );
      case FuelPriceCountry.romania:
        return const FuelPriceSnapshot(
          country: FuelPriceCountry.romania,
          currencyCode: 'RON',
          gasolineCurrent: 7.58,
          gasolineReference: 7.42,
          dieselCurrent: 7.81,
          dieselReference: 7.66,
          comparisonLabel: 'vs one month ago',
          sourceName: 'GlobalPetrolPrices',
          sourceUrl: 'https://www.globalpetrolprices.com/Romania/',
          sourceDescription:
              'Weekly gasoline and diesel prices from official and market sources.',
        );
      case FuelPriceCountry.germany:
        return const FuelPriceSnapshot(
          country: FuelPriceCountry.germany,
          currencyCode: 'EUR',
          gasolineCurrent: 1.86,
          gasolineReference: 1.81,
          dieselCurrent: 1.74,
          dieselReference: 1.70,
          comparisonLabel: 'vs one month ago',
          sourceName: 'GlobalPetrolPrices',
          sourceUrl: 'https://www.globalpetrolprices.com/Germany/',
          sourceDescription:
              'Weekly gasoline and diesel prices from official and market sources.',
        );
      case FuelPriceCountry.unitedStates:
        return const FuelPriceSnapshot(
          country: FuelPriceCountry.unitedStates,
          currencyCode: 'USD',
          gasolineCurrent: 0.96,
          gasolineReference: 0.92,
          dieselCurrent: 1.03,
          dieselReference: 0.99,
          comparisonLabel: 'vs one month ago',
          sourceName: 'GlobalPetrolPrices',
          sourceUrl: 'https://www.globalpetrolprices.com/United_States/',
          sourceDescription:
              'Weekly gasoline and diesel prices from official and market sources.',
        );
    }
  }
}

double _percentChange({required double current, required double reference}) {
  if (reference == 0) {
    return 0;
  }
  return (current - reference) / reference * 100;
}

double _parseDecimal(String raw) {
  return double.parse(raw.replaceAll(',', '.').trim());
}

double _matchDoubleAny(String text, List<String> patterns) {
  for (final pattern in patterns) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    if (match != null && match.group(1) != null) {
      return double.parse(match.group(1)!);
    }
  }
  throw FormatException('None of the patterns matched.');
}

double _sanitizeReference({
  required double current,
  required double reference,
}) {
  if (current <= 0 || reference <= 0) {
    return current > 0 ? current : 1;
  }

  final ratio = current / reference;
  if (ratio > 2.5 || ratio < 0.4) {
    return current;
  }

  return reference;
}

DateTime _parseDateIso(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime _parseDateDotted(String value) {
  final parts = value.split('.').map(int.parse).toList();
  return DateTime(parts[2], parts[1], parts[0]);
}

String _stripHtml(String html) {
  final noScript = html.replaceAll(
    RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
    ' ',
  );
  final noStyle = noScript.replaceAll(
    RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
    ' ',
  );
  return noStyle
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
