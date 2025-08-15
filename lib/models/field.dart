// lib/models/field.dart

class Field {
  final String id;
  final String name;
  final String openHour;
  final String closeHour;
  final int pricePerHour;

  Field({
    required this.id,
    required this.name,
    required this.openHour,
    required this.closeHour,
    required this.pricePerHour,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'openHour': openHour,
    'closeHour': closeHour,
    'pricePerHour': pricePerHour,
  };

  factory Field.fromMap(Map<String, dynamic> map) => Field(
    id: map['id'],
    name: map['name'] ?? '',
    openHour: map['openHour'] ?? '08:00',
    closeHour: map['closeHour'] ?? '22:00',
    pricePerHour: (map['pricePerHour'] ?? 100000) as int,
  );
}
