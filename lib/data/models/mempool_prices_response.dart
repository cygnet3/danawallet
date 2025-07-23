class MempoolPricesResponse {
  final int timestamp;
  final int usd;
  final int eur;
  final int gbp;
  final int cad;
  final int chf;
  final int aud;
  final int jpy;

  const MempoolPricesResponse({
    required this.timestamp,
    required this.usd,
    required this.eur,
    required this.gbp,
    required this.cad,
    required this.chf,
    required this.aud,
    required this.jpy,
  });

  factory MempoolPricesResponse.fromJson(Map<String, dynamic> json) {
    return MempoolPricesResponse(
        timestamp: json['time'] as int,
        usd: json['USD'] as int,
        eur: json['EUR'] as int,
        gbp: json['GBP'] as int,
        cad: json['CAD'] as int,
        chf: json['CHF'] as int,
        aud: json['AUD'] as int,
        jpy: json['JPY'] as int);
  }
}
