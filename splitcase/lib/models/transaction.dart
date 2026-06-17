// models/transaction.dart — Orang 1
class Transaction {
  final int? id;
  final int groupId;
  final int payerContactId;
  final double amount;
  final String description;
  final String date;
  final String? receiptImagePath;

  Transaction({
    this.id,
    required this.groupId,
    required this.payerContactId,
    required this.amount,
    required this.description,
    this.receiptImagePath,
    String? date,
  }) : date = date ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'payer_contact_id': payerContactId,
        'amount': amount,
        'description': description,
        'date': date,
        if (receiptImagePath != null) 'receipt_image_path': receiptImagePath,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as int?,
        groupId: map['group_id'] as int,
        payerContactId: map['payer_contact_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        description: map['description'] as String,
        date: map['date'] as String,
        receiptImagePath: map['receipt_image_path'] as String?,
      );

  Transaction copyWith({
    int? id,
    int? groupId,
    int? payerContactId,
    double? amount,
    String? description,
    String? date,
    String? receiptImagePath,
  }) =>
      Transaction(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        payerContactId: payerContactId ?? this.payerContactId,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        date: date ?? this.date,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      );

  @override
  String toString() =>
      'Transaction(id: $id, groupId: $groupId, amount: $amount, description: $description)';
}
