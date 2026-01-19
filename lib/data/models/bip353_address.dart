class Bip353Address {
  String username;
  String domain;

  Bip353Address({required this.username, required this.domain});

  factory Bip353Address.fromString(String address) {
    if (address.isEmpty) {
      throw Exception("Address is empty");
    }

    if (!RegExp(r'^[a-z0-9]', caseSensitive: false).hasMatch(address[0])) {
      throw Exception(
          "Bip353 address does not start with a letter or digit: $address");
    }

    // Valid characters for dana address (username@domain format)
    final validAddressPattern =
        RegExp(r'^[a-z0-9._-]+@[a-z0-9.-]+\.[a-z]+$', caseSensitive: false);
    if (!validAddressPattern.hasMatch(address)) {
      throw Exception("Invalid bip353 address pattern: $address");
    }

    final parts = address.toLowerCase().split('@');
    if (parts.length != 2) {
      throw Exception("Invalid bip353 address pattern: $address");
    }

    // store everything in lower case
    final username = parts[0].toLowerCase();
    final domain = parts[1].toLowerCase();

    return Bip353Address(username: username, domain: domain);
  }

  @override
  String toString() {
    return "$username@$domain";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Bip353Address &&
        other.username == username &&
        other.domain == domain;
  }

  @override
  int get hashCode => Object.hash(username, domain);
}
