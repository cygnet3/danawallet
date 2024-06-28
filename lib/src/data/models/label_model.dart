class Label {
  final String label;
  final List<int> pubkey;

  Label({required this.label, required this.pubkey});

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      label: json['0'] as String,
      pubkey: List<int>.from(json['1'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0': label,
      '1': pubkey,
    };
  }
}
