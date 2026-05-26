// services/split_calculator.dart — Orang 1: split algorithm
import '../models/transaction.dart';
import '../models/contact.dart';

/// Hasil perhitungan: siapa hutang ke siapa berapa
class DebtEntry {
  final Contact debtor;   // yang hutang
  final Contact creditor; // yang berpiutang
  final double amount;

  DebtEntry({
    required this.debtor,
    required this.creditor,
    required this.amount,
  });

  @override
  String toString() =>
      '${debtor.name} hutang ke ${creditor.name} sebesar $amount';
}

/// Ringkasan saldo per kontak
class BalanceSummary {
  final Contact contact;
  final double paid;   // total yang sudah dibayar
  final double share;  // bagian fair yang harus dibayar
  double get balance => paid - share; // positif = berpiutang, negatif = hutang

  BalanceSummary({
    required this.contact,
    required this.paid,
    required this.share,
  });
}

class SplitCalculator {
  /// Hitung daftar hutang dari list transaksi & kontak.
  ///
  /// [transactions] — semua transaksi dalam satu grup
  /// [contacts]     — semua anggota grup
  ///
  /// Algoritma:
  /// 1. Hitung total yang dibayar per orang
  /// 2. Hitung rata-rata (share) = total / n
  /// 3. Hitung balance = paid - share
  /// 4. Pakai greedy: yang paling minus bayar ke yang paling plus
  static List<DebtEntry> calculate({
    required List<Transaction> transactions,
    required List<Contact> contacts,
  }) {
    if (contacts.isEmpty || transactions.isEmpty) return [];

    // Step 1: total dibayar per contactId
    final Map<int, double> paid = {for (var c in contacts) c.id!: 0.0};
    for (final tx in transactions) {
      paid[tx.payerContactId] = (paid[tx.payerContactId] ?? 0) + tx.amount;
    }

    // Step 2: rata-rata per orang
    final double total = paid.values.fold(0.0, (a, b) => a + b);
    final double share = total / contacts.length;

    // Step 3: balance per orang
    final Map<int, double> balance = {
      for (var c in contacts) c.id!: (paid[c.id!] ?? 0) - share,
    };

    // Step 4: greedy settlement
    final List<DebtEntry> debts = [];
    final contactMap = {for (var c in contacts) c.id!: c};

    // Pisahkan debtors (balance < 0) dan creditors (balance > 0)
    final debtors = balance.entries
        .where((e) => e.value < -0.01)
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // paling minus duluan

    final creditors = balance.entries
        .where((e) => e.value > 0.01)
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // paling plus duluan

    int i = 0, j = 0;
    final debtorBalances = debtors.map((e) => e.value).toList();
    final creditorBalances = creditors.map((e) => e.value).toList();

    while (i < debtors.length && j < creditors.length) {
      final debtAmount = -debtorBalances[i]; // jadikan positif
      final creditAmount = creditorBalances[j];
      final settled = debtAmount < creditAmount ? debtAmount : creditAmount;

      if (settled > 0.01) {
        debts.add(DebtEntry(
          debtor: contactMap[debtors[i].key]!,
          creditor: contactMap[creditors[j].key]!,
          amount: _round(settled),
        ));
      }

      debtorBalances[i] += settled;
      creditorBalances[j] -= settled;

      if (debtorBalances[i].abs() < 0.01) i++;
      if (creditorBalances[j].abs() < 0.01) j++;
    }

    return debts;
  }

  /// Ringkasan saldo per kontak (untuk DebtBalanceCard)
  static List<BalanceSummary> balanceSummaries({
    required List<Transaction> transactions,
    required List<Contact> contacts,
  }) {
    if (contacts.isEmpty) return [];

    final Map<int, double> paid = {for (var c in contacts) c.id!: 0.0};
    for (final tx in transactions) {
      paid[tx.payerContactId] = (paid[tx.payerContactId] ?? 0) + tx.amount;
    }

    final double total = paid.values.fold(0.0, (a, b) => a + b);
    final double share = contacts.isEmpty ? 0 : total / contacts.length;

    return contacts
        .map((c) => BalanceSummary(
              contact: c,
              paid: paid[c.id!] ?? 0,
              share: share,
            ))
        .toList();
  }

  /// Total pengeluaran grup
  static double totalExpense(List<Transaction> transactions) =>
      transactions.fold(0.0, (sum, tx) => sum + tx.amount);

  static double _round(double v) => (v * 100).round() / 100;
}
