class ContactField {
  int? id;
  final int contactId;
  final String
      fieldType; // e.g., 'email', 'twitter', 'telegram', 'github', etc.
  final String fieldValue;

  ContactField({
    this.id,
    required this.contactId,
    required this.fieldType,
    required this.fieldValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'field_type': fieldType,
      'field_value': fieldValue,
    };
  }

  factory ContactField.fromMap(Map<String, dynamic> map) {
    return ContactField(
      id: map['id'],
      contactId: map['contact_id'],
      fieldType: map['field_type'],
      fieldValue: map['field_value'],
    );
  }
}
