// lib/services/split_calculator.dart
import '../models/transaction.dart';
import '../models/contact.dart';
import '../models/settlement.dart';

class DebtEntry {
  final Contact debtor;
  final Contact creditor;
  final double amount;

  DebtEntry({required this.debtor, required this.creditor, required this.amount});
}

class BalanceSummary {
  final Contact contact;
  final double paid;
  final double share;
  final double settled; // total yang sudah dilunasi via settlement
  double get balance => paid - share + settled;

  BalanceSummary({
    required this.contact,
    required this.paid,
    required this.share,
    this.settled = 0,
  });
}

class SplitCalculator {
  /// Hitung siapa bayar siapa, memperhitungkan pelunasan yang sudah terjadi.
  static List<DebtEntry> calculate({
    required List<Transaction> transactions,
    required List<Contact> contacts,
    List<Settlement> settlements = const [],
  }) {
    if (contacts.isEmpty) return [];

    final Map<int, double> paid = {for (var c in contacts) c.id!: 0.0};

    for (final tx in transactions) {
      if (paid.containsKey(tx.payerContactId)) {
        paid[tx.payerContactId] = (paid[tx.payerContactId] ?? 0) + tx.amount;
      }
    }

    final double total = paid.values.fold(0.0, (a, b) => a + b);
    final double share = contacts.isEmpty ? 0 : total / contacts.length;

    // Hitung saldo awal (bayar - bagian)
    final Map<int, double> balance = {
      for (var c in contacts) c.id!: (paid[c.id!] ?? 0) - share,
    };

    // Kurangi hutang dengan pelunasan yang sudah terjadi
    // Settlement: fromContact membayar toContact
    // → fromContact saldo naik (hutangnya berkurang)
    // → toContact saldo turun (piutangnya berkurang)
    for (final s in settlements) {
      if (balance.containsKey(s.fromContactId)) {
        balance[s.fromContactId] = balance[s.fromContactId]! + s.amount;
      }
      if (balance.containsKey(s.toContactId)) {
        balance[s.toContactId] = balance[s.toContactId]! - s.amount;
      }
    }

    final debtors = balance.entries.where((e) => e.value < -0.01).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final creditors = balance.entries.where((e) => e.value > 0.01).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<DebtEntry> debts = [];
    final contactMap = {for (var c in contacts) c.id!: c};

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final debt = -debtors[i].value;
      final credit = creditors[j].value;
      final settled = debt < credit ? debt : credit;

      if (settled > 0.01) {
        debts.add(DebtEntry(
          debtor: contactMap[debtors[i].key]!,
          creditor: contactMap[creditors[j].key]!,
          amount: (settled * 100).round() / 100,
        ));
      }

      debtors[i] = MapEntry(debtors[i].key, debtors[i].value + settled);
      creditors[j] = MapEntry(creditors[j].key, creditors[j].value - settled);

      if (debtors[i].value.abs() < 0.01) i++;
      if (creditors[j].value.abs() < 0.01) j++;
    }

    return debts;
  }

  /// Ringkasan saldo per orang, sudah memperhitungkan pelunasan.
  static List<BalanceSummary> balanceSummaries({
    required List<Transaction> transactions,
    required List<Contact> contacts,
    List<Settlement> settlements = const [],
  }) {
    if (contacts.isEmpty) return [];

    final Map<int, double> paid = {for (var c in contacts) c.id!: 0.0};
    for (final tx in transactions) {
      if (paid.containsKey(tx.payerContactId)) {
        paid[tx.payerContactId] = (paid[tx.payerContactId] ?? 0) + tx.amount;
      }
    }

    final double total = paid.values.fold(0.0, (a, b) => a + b);
    final double share = contacts.isEmpty ? 0 : total / contacts.length;

    // Hitung settled per orang:
    // fromContact: sudah membayar hutangnya → settled positif (hutang berkurang)
    // toContact: menerima pembayaran → settled negatif (piutang berkurang)
    final Map<int, double> settledMap = {for (var c in contacts) c.id!: 0.0};
    for (final s in settlements) {
      if (settledMap.containsKey(s.fromContactId)) {
        settledMap[s.fromContactId] = settledMap[s.fromContactId]! + s.amount;
      }
      if (settledMap.containsKey(s.toContactId)) {
        settledMap[s.toContactId] = settledMap[s.toContactId]! - s.amount;
      }
    }

    return contacts
        .map((c) => BalanceSummary(
              contact: c,
              paid: paid[c.id!] ?? 0,
              share: share,
              settled: settledMap[c.id!] ?? 0,
            ))
        .toList();
  }

  static double totalExpense(List<Transaction> transactions) =>
      transactions.fold(0.0, (sum, tx) => sum + tx.amount);
}
