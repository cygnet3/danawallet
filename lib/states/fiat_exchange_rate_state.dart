import 'package:danawallet/exceptions.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class FiatExchangeRateState extends ChangeNotifier {
  MempoolApiRepository repository = MempoolApiRepository();

  late FiatCurrency currency;
  late FiatExchangeRate _cachedRate;

  // private constructor, create class using static async 'create' instead
  FiatExchangeRateState._();

  static Future<FiatExchangeRateState> create() async {
    final instance = FiatExchangeRateState._();
    final currency = await SettingsRepository.instance.getFiatCurrency();
    final rate = await instance._fetchExchangeRate(currency);

    // set internal values
    instance.currency = currency;
    instance._cachedRate = rate;

    return instance;
  }

  FiatExchangeRate get exchangeRate {
    try {
      return _cachedRate;
    } catch (e) {
      throw UninitializedExchangeRateException();
    }
  }

  Future<void> updateCurrency(FiatCurrency currency) async {
    await SettingsRepository.instance.setFiatCurrency(currency);
    this.currency = currency;

    // after updating the currency, also update the exchange rate
    return await updateExchangeRate();
  }

  Future<void> updateExchangeRate() async {
    final rate = await _fetchExchangeRate(currency);

    Logger().i("Updating exchange rate: ${rate.currency.displayName()}");
    _cachedRate = rate;

    notifyListeners();
  }

  Future<FiatExchangeRate> _fetchExchangeRate(FiatCurrency currency) async {
    final rates = await repository.getExchangeRate();

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
