// models/contact.dart — Orang 2
class Contact {
  final int? id;
  final String name;
  final String phone;
  final String avatarColor;

  Contact({
    this.id,
    required this.name,
    this.phone = '',
    this.avatarColor = '#2196F3',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'avatar_color': avatarColor,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        avatarColor: map['avatar_color'] as String? ?? '#2196F3',
      );

  Contact copyWith({int? id, String? name, String? phone, String? avatarColor}) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        avatarColor: avatarColor ?? this.avatarColor,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  String toString() => 'Contact(id: $id, name: $name, phone: $phone)';
}
