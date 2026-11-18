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
  Stream<DashboardSummary> getTodaySummary() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('transactions')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .snapshots()
        .map((snapshot) {
      double revenue = 0;
      for (final doc in snapshot.docs) {
        revenue += (doc.data()['finalTotal'] as num?)?.toDouble() ?? 0;
      }

      return DashboardSummary(
        revenue: revenue,
        transactionCount: snapshot.docs.length,
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
