import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_currency.dart';
import '../models/bank_rate.dart';
import 'bank_rates_cbu_fetch_stub.dart'
    if (dart.library.io) 'bank_rates_cbu_fetch_io.dart';

/// O'zbekiston MB rasmiy kurslari (CBU) + mahalliy kesh.
class BankRatesService {
  BankRatesService._();
  static final BankRatesService instance = BankRatesService._();

  static const _cacheKey = 'bank_rates_cache_v1';
  static const _cacheDateKey = 'bank_rates_date_v1';

  final Map<AppCurrency, BankRate> _rates = {};
  DateTime? _lastUpdated;
  bool _loaded = false;
  bool _loading = false;
  String? _lastError;

  /// Vebda brauzer CORS tufayli CBU dan to'g'ridan yuklamaydi.
  bool get isWebPlatform => kIsWeb;

  List<BankRate> get rates => AppCurrency.values
      .where((c) => c != AppCurrency.uzs)
      .map(rateFor)
      .toList();

  DateTime? get lastUpdated => _lastUpdated;
  String? get lastError => _lastError;
  bool get isLoaded => _loaded;

  BankRate rateFor(AppCurrency currency) {
    if (currency == AppCurrency.uzs) {
      return BankRate(
        currency: AppCurrency.uzs,
        rateUzs: 1,
        source: 'base',
        updatedAt: _lastUpdated,
      );
    }
    return _rates[currency] ??
        BankRate(
          currency: currency,
          rateUzs: currency.defaultRateToUzs(),
          source: 'default',
        );
  }

  double rateBetween(AppCurrency from, AppCurrency settlement) {
    if (from == settlement) return 1;
    return rateFor(from).perUnit / rateFor(settlement).perUnit;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _loadCache();
    if (_loaded) return;

    if (kIsWeb) {
      _applyDefaults();
      _loaded = true;
      _lastError =
          'Brauzerda CBU dan avtomatik yuklanmaydi — standart kurslar ishlatiladi';
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _lastError = null;

    try {
      if (kIsWeb) {
        await _loadCache();
        if (!_loaded) {
          _applyDefaults();
          _loaded = true;
        }
        _lastError = _rates.values.any((r) => r.source == 'cbu')
            ? null
            : 'Veb: yangilash uchun mobil ilovadan foydalaning yoki standart kurslar';
        return;
      }

      final list = await fetchCbuRatesJson();
      if (list == null) {
        throw Exception('CBU yuklanmadi');
      }
      _applyCbuJson(list);
      _lastUpdated = DateTime.now();
      _loaded = true;
      await _saveCache();
    } catch (e) {
      _lastError = e.toString();
      if (!_loaded) {
        await _loadCache();
        if (!_loaded) {
          _applyDefaults();
          _loaded = true;
        }
      }
    } finally {
      _loading = false;
    }
  }

  void _applyCbuJson(List<dynamic> list) {
    final byCode = <String, Map<String, dynamic>>{};
    for (final raw in list) {
      if (raw is Map) {
        byCode[raw['Ccy']?.toString() ?? ''] = Map<String, dynamic>.from(raw);
      }
    }

    for (final currency in AppCurrency.values) {
      if (currency == AppCurrency.uzs) continue;
      final row = byCode[currency.code];
      if (row != null) {
        final nominal =
            int.tryParse(row['Nominal']?.toString() ?? '1') ?? 1;
        final rateStr = row['Rate']?.toString() ?? '';
        final rate = double.tryParse(rateStr.replaceAll(',', '.')) ??
            currency.defaultRateToUzs();
        _rates[currency] = BankRate(
          currency: currency,
          rateUzs: rate,
          nominal: nominal,
          source: 'cbu',
          updatedAt: DateTime.now(),
        );
      } else {
        _rates[currency] = BankRate(
          currency: currency,
          rateUzs: currency.defaultRateToUzs(),
          nominal: 1,
          source: 'default',
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  void _applyDefaults() {
    for (final currency in AppCurrency.values) {
      if (currency == AppCurrency.uzs) continue;
      _rates[currency] = BankRate(
        currency: currency,
        rateUzs: currency.defaultRateToUzs(),
        source: 'default',
        updatedAt: DateTime.now(),
      );
    }
    _lastUpdated = DateTime.now();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      final dateStr = prefs.getString(_cacheDateKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((code, value) {
        if (value is! Map) return;
        final currency = AppCurrency.fromCode(code);
        if (currency == AppCurrency.uzs) return;
        _rates[currency] = BankRate(
          currency: currency,
          rateUzs: (value['rateUzs'] as num).toDouble(),
          nominal: value['nominal'] as int? ?? 1,
          source: value['source'] as String? ?? 'cache',
          updatedAt: dateStr != null ? DateTime.tryParse(dateStr) : null,
        );
      });
      _lastUpdated = dateStr != null ? DateTime.tryParse(dateStr) : null;
      if (_rates.isNotEmpty) _loaded = true;
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final e in _rates.entries) {
      map[e.key.code] = {
        'rateUzs': e.value.rateUzs,
        'nominal': e.value.nominal,
        'source': e.value.source,
      };
    }
    await prefs.setString(_cacheKey, jsonEncode(map));
    if (_lastUpdated != null) {
      await prefs.setString(_cacheDateKey, _lastUpdated!.toIso8601String());
    }
  }
}
