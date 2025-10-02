import 'package:danawallet/data/models/mempool_prices_response.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class FiatExchangeRateState extends ChangeNotifier {
  MempoolApiRepository repository = MempoolApiRepository();

  late FiatCurrency currency;
  FiatExchangeRate? _cachedRate; // Make nullable to represent "no data available"
  bool get hasExchangeRate => _cachedRate != null;

  // private constructor, create class using static async 'create' instead
  FiatExchangeRateState._();

  static Future<FiatExchangeRateState> create() async {
    final instance = FiatExchangeRateState._();
    final currency = await SettingsRepository.instance.getFiatCurrency();
    instance.currency = currency;

    try {
      final rate = await instance._fetchExchangeRate(currency);
      instance._cachedRate = rate;
    } catch (e) {
      Logger().w('Failed to fetch exchange rate: $e');
      instance._cachedRate = null;
    }

    return instance;
  }

  FiatExchangeRate? get exchangeRate {
    return _cachedRate; // Can be null if no data available
  }

  /// Returns a display string for unavailable fiat amounts using the currency symbol
  String getUnavailableDisplay() {
    return '--${currency.symbol()}';
  }

  Future<void> updateCurrency(FiatCurrency currency) async {
    await SettingsRepository.instance.setFiatCurrency(currency);
    this.currency = currency;
    
    // Reset exchange rate when currency changes
    _cachedRate = null;
    notifyListeners();

    // Try to fetch fresh data for new currency
    try {
      await updateExchangeRate();
    } catch (e) {
      _cachedRate = null;
      rethrow;
    }
  }

  Future<void> updateExchangeRate() async {
    try {
      final rate = await _fetchExchangeRate(currency);
      Logger().i("Updating exchange rate: ${rate.currency.displayName()}");
      _cachedRate = rate;
      notifyListeners();
    } catch (e) {
      _cachedRate = null;
      rethrow;
    }
  }

  Future<FiatExchangeRate> _fetchExchangeRate(FiatCurrency currency) async {
    MempoolPricesResponse? rates;
    try {
      rates = await repository.getExchangeRate();
    } catch (e) {
      rethrow;
    }

    final double rate;
    switch (currency) {
      case FiatCurrency.eur:
        rate = rates.eur.toDouble();
        break;
      case FiatCurrency.usd:
        rate = rates.usd.toDouble();
        break;
      case FiatCurrency.gbp:
        rate = rates.gbp.toDouble();
        break;
      case FiatCurrency.cad:
        rate = rates.cad.toDouble();
        break;
      case FiatCurrency.chf:
        rate = rates.chf.toDouble();
        break;
      case FiatCurrency.aud:
        rate = rates.aud.toDouble();
        break;
      case FiatCurrency.jpy:
        rate = rates.jpy.toDouble();
        break;
    }
    return FiatExchangeRate(currency: currency, exchangeRate: rate);
  }
}
