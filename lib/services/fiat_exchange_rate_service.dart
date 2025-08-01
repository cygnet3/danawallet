import 'package:danawallet/exceptions.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:logger/logger.dart';

class FiatExchangeRateService {
  MempoolApiRepository repository = MempoolApiRepository();

  late FiatCurrency currency;
  late FiatExchangeRate _cachedRate;

  // private constructor
  FiatExchangeRateService._();

  // singleton instance
  static final instance = FiatExchangeRateService._();

  FiatExchangeRate get exchangeRate {
    try {
      return _cachedRate;
    } catch (e) {
      throw UninitializedExchangeRateException();
    }
  }

  // this only gets called once during app initialization
  // todo: periodically update exchange rate (?)
  Future<void> updateExchangeRate() async {
    currency = await SettingsRepository.instance.getFiatCurrency();
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

    Logger().i("Updating exchange rate: $rate");

    _cachedRate = FiatExchangeRate(currency: currency, exchangeRate: rate);
  }
}
