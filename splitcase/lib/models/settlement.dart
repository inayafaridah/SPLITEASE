// lib/models/settlement.dart
class Settlement {
  final int? id;
  final int? groupId;           // ← Baru: support grup
  final int fromContactId;
  final int toContactId;
  final double amount;
  final String date;
  final String note;
  final int isPaid;             // 0 = pending, 1 = paid

  Settlement({
    this.id,
    this.groupId,               // ← Ditambahkan
    required this.fromContactId,
    required this.toContactId,
    required this.amount,
    String? date,
    this.note = '',
    this.isPaid = 0,            // ← Default 0 (pending)
  }) : date = date ?? DateTime.now().toIso8601String();

  bool get paid => isPaid == 1;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (groupId != null) 'group_id': groupId,
        'from_contact_id': fromContactId,
        'to_contact_id': toContactId,
        'amount': amount,
        'date': date,
        'note': note,
        'is_paid': isPaid,
      };

  factory Settlement.fromMap(Map<String, dynamic> map) => Settlement(
        id: map['id'] as int?,
        groupId: map['group_id'] as int?,
        fromContactId: map['from_contact_id'] as int,
        toContactId: map['to_contact_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String? ?? '',
        isPaid: map['is_paid'] as int? ?? 0,
      );

  Settlement copyWith({
    int? id,
    int? groupId,
    int? fromContactId,
    int? toContactId,
    double? amount,
    String? date,
    String? note,
    int? isPaid,
  }) =>
      Settlement(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        fromContactId: fromContactId ?? this.fromContactId,
        toContactId: toContactId ?? this.toContactId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
        isPaid: isPaid ?? this.isPaid,
      );

  @override
  String toString() =>
      'Settlement(id: $id, group: $groupId, from: $fromContactId → to: $toContactId, amount: $amount, paid: $paid)';
}