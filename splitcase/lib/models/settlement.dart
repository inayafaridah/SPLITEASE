// models/settlement.dart — Orang 2
class Settlement {
  final int? id;
  final int fromContactId;
  final int toContactId;
  final double amount;
  final String date;
  final String note;
  final int isPaid; // 0 = pending, 1 = paid

  Settlement({
    this.id,
    required this.fromContactId,
    required this.toContactId,
    required this.amount,
    String? date,
    this.note = '',
    this.isPaid = 0,
  }) : date = date ?? DateTime.now().toIso8601String();

  bool get paid => isPaid == 1;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'from_contact_id': fromContactId,
        'to_contact_id': toContactId,
        'amount': amount,
        'date': date,
        'note': note,
        'is_paid': isPaid,
      };

  factory Settlement.fromMap(Map<String, dynamic> map) => Settlement(
        id: map['id'] as int?,
        fromContactId: map['from_contact_id'] as int,
        toContactId: map['to_contact_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String? ?? '',
        isPaid: map['is_paid'] as int? ?? 0,
      );

  Settlement copyWith({
    int? id,
    int? fromContactId,
    int? toContactId,
    double? amount,
    String? date,
    String? note,
    int? isPaid,
  }) =>
      Settlement(
        id: id ?? this.id,
        fromContactId: fromContactId ?? this.fromContactId,
        toContactId: toContactId ?? this.toContactId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
        isPaid: isPaid ?? this.isPaid,
      );

  @override
  String toString() =>
      'Settlement(id: $id, from: $fromContactId, to: $toContactId, amount: $amount, paid: $paid)';
}
