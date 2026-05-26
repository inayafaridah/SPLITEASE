// models/group.dart — Orang 1
class Group {
  final int? id;
  final String name;
  final String currency;
  final String createdAt;

  Group({
    this.id,
    required this.name,
    this.currency = 'IDR',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'currency': currency,
        'created_at': createdAt,
      };

  factory Group.fromMap(Map<String, dynamic> map) => Group(
        id: map['id'] as int?,
        name: map['name'] as String,
        currency: map['currency'] as String? ?? 'IDR',
        createdAt: map['created_at'] as String,
      );

  Group copyWith({int? id, String? name, String? currency, String? createdAt}) =>
      Group(
        id: id ?? this.id,
        name: name ?? this.name,
        currency: currency ?? this.currency,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'Group(id: $id, name: $name, currency: $currency)';
}
