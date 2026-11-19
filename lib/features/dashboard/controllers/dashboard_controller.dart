import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pos/models/transaction_models.dart';

/// Ringkasan transaksi hari ini untuk kartu dashboard.
class DashboardSummary {
  final double revenue;
  final int transactionCount;

  const DashboardSummary({
    required this.revenue,
    required this.transactionCount,
  });
}

class DashboardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Omzet dan jumlah transaksi sejak pukul 00:00 hari ini.
  /// Admin melihat seluruh transaksi; kasir hanya melihat transaksinya sendiri.
  Stream<DashboardSummary> getTodaySummary({
    required bool isAdmin,
    required String cashierId,
  }) {
    if (!isAdmin && cashierId.trim().isEmpty) {
      return Stream.value(
        const DashboardSummary(revenue: 0, transactionCount: 0),
      );
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    Query<Map<String, dynamic>> query = _firestore
        .collection('transactions')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        );

    if (!isAdmin) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }

    return query.snapshots().map((snapshot) {
      double revenue = 0;
      var transactionCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Nota yang dibatalkan tidak dihitung ke omzet maupun jumlah nota.
        if (data['voided'] == true) continue;

        revenue += (data['finalTotal'] as num?)?.toDouble() ?? 0;
        transactionCount++;
      }

      return DashboardSummary(
        revenue: revenue,
        transactionCount: transactionCount,
      );
    });
  }

  /// Transaksi terbaru untuk bagian "Aktivitas Terakhir" (khusus admin).
  Stream<List<TransactionModel>> getRecentTransactions({int limit = 5}) {
    return _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}