class SpendKey {
  final String secret;

  SpendKey({required this.secret});

  factory SpendKey.fromJson(Map<String, dynamic> json) {
    return SpendKey(secret: json['Secret']);
  }

  Map<String, dynamic> toJson() {
    return {'Secret': secret};
  }
}
