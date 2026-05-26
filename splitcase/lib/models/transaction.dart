// models/transaction.dart — Orang 1
class Transaction {
  final int? id;
  final int groupId;
  final int payerContactId;
  final double amount;
  final String description;
  final String date;

  Transaction({
    this.id,
    required this.groupId,
    required this.payerContactId,
    required this.amount,
    required this.description,
    String? date,
  }) : date = date ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'payer_contact_id': payerContactId,
        'amount': amount,
        'description': description,
        'date': date,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as int?,
        groupId: map['group_id'] as int,
        payerContactId: map['payer_contact_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        description: map['description'] as String,
        date: map['date'] as String,
      );

  Transaction copyWith({
    int? id,
    int? groupId,
    int? payerContactId,
    double? amount,
    String? description,
    String? date,
  }) =>
      Transaction(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        payerContactId: payerContactId ?? this.payerContactId,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        date: date ?? this.date,
      );

  @override
  String toString() =>
      'Transaction(id: $id, groupId: $groupId, amount: $amount, description: $description)';
}
