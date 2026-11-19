import 'dart:async';

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
  ///
  /// Rentang tanggal dihitung ulang otomatis tepat setelah tengah malam,
  /// supaya aplikasi yang dibiarkan terbuka tidak terus menghitung hari
  /// sebelumnya.
  Stream<DashboardSummary> getTodaySummary({
    required bool isAdmin,
    required String cashierId,
  }) {
    if (!isAdmin && cashierId.trim().isEmpty) {
      return Stream.value(
        const DashboardSummary(revenue: 0, transactionCount: 0),
      );
    }

    late StreamController<DashboardSummary> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
    Timer? midnightTimer;

    void subscribe() {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final nextDay = startOfDay.add(const Duration(days: 1));

      Query<Map<String, dynamic>> query = _firestore
          .collection('transactions')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          );

      if (!isAdmin) {
        query = query.where('cashierId', isEqualTo: cashierId);
      }

      subscription = query.snapshots().listen(
        (snapshot) => controller.add(_summarize(snapshot)),
        onError: controller.addError,
      );

      midnightTimer?.cancel();
      midnightTimer = Timer(
        nextDay.difference(now) + const Duration(seconds: 1),
        () {
          if (controller.isClosed) return;
          subscription?.cancel();
          subscription = null;
          subscribe();
        },
      );
    }

    controller = StreamController<DashboardSummary>(
      onListen: subscribe,
      onCancel: () {
        midnightTimer?.cancel();
        midnightTimer = null;
        subscription?.cancel();
        subscription = null;
      },
    );

    return controller.stream;
  }

  DashboardSummary _summarize(QuerySnapshot<Map<String, dynamic>> snapshot) {
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