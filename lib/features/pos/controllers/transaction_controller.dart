import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/transaction_models.dart';

/// Hasil agregasi sekumpulan nota. Nota yang dibatalkan (void) tidak
/// dihitung ke omzet maupun jumlah transaksi, tetapi tetap dicatat.
class SalesReport {
  final int transactionCount;
  final int itemCount;
  final double revenue;
  final double discountTotal;
  final int voidedCount;

  const SalesReport({
    required this.transactionCount,
    required this.itemCount,
    required this.revenue,
    required this.discountTotal,
    required this.voidedCount,
  });

  static const SalesReport empty = SalesReport(
    transactionCount: 0,
    itemCount: 0,
    revenue: 0,
    discountTotal: 0,
    voidedCount: 0,
  );

  factory SalesReport.fromTransactions(Iterable<TransactionModel> transactions) {
    var count = 0;
    var items = 0;
    var voided = 0;
    var revenue = 0.0;
    var discount = 0.0;

    for (final transaction in transactions) {
      if (transaction.voided) {
        voided++;
        continue;
      }

      count++;
      revenue += transaction.finalTotal;
      discount += transaction.discount;
      items += transaction.itemCount;
    }

    return SalesReport(
      transactionCount: count,
      itemCount: items,
      revenue: revenue,
      discountTotal: discount,
      voidedCount: voided,
    );
  }

  double get averagePerTransaction =>
      transactionCount == 0 ? 0 : revenue / transactionCount;
}

/// Rekap penjualan per produk, dihitung dari isi nota.
class ProductSales {
  final String productId;
  final String productName;
  final int quantity;
  final double revenue;

  const ProductSales({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });
}

class TransactionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  /// Stream riwayat transaksi.
  ///
  /// Admin melihat semua nota; kasir hanya nota miliknya sendiri.
  /// [start] inklusif dan [end] eksklusif (memudahkan filter per hari).
  Stream<List<TransactionModel>> getTransactions({
    required bool isAdmin,
    required String cashierId,
    DateTime? start,
    DateTime? end,
    int limit = 100,
  }) {
    if (!isAdmin && cashierId.trim().isEmpty) {
      return Stream.value(const <TransactionModel>[]);
    }

    Query<Map<String, dynamic>> query = _transactions;

    if (!isAdmin) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }
    if (start != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (end != null) {
      query = query.where('createdAt', isLessThan: Timestamp.fromDate(end));
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Ambil satu nota (dipakai saat membuka struk dari riwayat).
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final doc = await _transactions.doc(transactionId).get();
      if (!doc.exists) return null;
      return TransactionModel.fromMap(doc.data() ?? const {}, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Batalkan nota (khusus admin) dan kembalikan stok produk.
  ///
  /// Stok hanya dikembalikan sekali: penanda `voided` di dokumen transaksi
  /// membuat percobaan kedua ditolak di dalam transaksi Firestore.
  Future<String?> voidTransaction(String transactionId) async {
    if (!AuthController.isAdmin) {
      return 'Hanya admin yang dapat membatalkan transaksi.';
    }

    final adminId = AuthController.currentUser?.id;
    if (adminId == null) {
      return 'Sesi login tidak valid. Silakan login ulang.';
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final transactionRef = _transactions.doc(transactionId);
        final snapshot = await transaction.get(transactionRef);

        if (!snapshot.exists) {
          throw Exception('Transaksi tidak ditemukan.');
        }

        final data = snapshot.data() ?? const <String, dynamic>{};
        if (data['voided'] == true) {
          throw Exception('Transaksi ini sudah dibatalkan.');
        }

        // Baca semua produk dulu, baru tulis (aturan transaksi Firestore).
        final restoredStocks = <DocumentReference, int>{};
        final rawItems = data['items'];

        if (rawItems is List) {
          for (final rawItem in rawItems) {
            if (rawItem is! Map) continue;

            final item = Map<String, dynamic>.from(rawItem);
            final productId = item['productId']?.toString() ?? '';
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            if (productId.isEmpty || quantity <= 0) continue;

            final productRef = _firestore.collection('products').doc(productId);
            final productSnapshot = await transaction.get(productRef);
            if (!productSnapshot.exists) continue;

            final currentStock =
                (productSnapshot.data()?['stock'] as num?)?.toInt() ?? 0;
            restoredStocks[productRef] = currentStock + quantity;
          }
        }

        restoredStocks.forEach((productRef, stock) {
          transaction.update(productRef, {
            'stock': stock,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });

        transaction.update(transactionRef, {
          'voided': true,
          'voidedAt': FieldValue.serverTimestamp(),
          'voidedBy': adminId,
        });
      });

      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Produk terlaris dari daftar nota (nota void diabaikan).
  static List<ProductSales> topProducts(
    Iterable<TransactionModel> transactions, {
    int limit = 5,
  }) {
    final quantities = <String, int>{};
    final names = <String, String>{};
    final revenues = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.voided) continue;

      for (final item in transaction.items) {
        final id = item.product.id;
        if (id.isEmpty) continue;

        quantities[id] = (quantities[id] ?? 0) + item.quantity;
        revenues[id] = (revenues[id] ?? 0) + item.totalPrice;
        names[id] = item.product.name;
      }
    }

    final result = quantities.entries
        .map(
          (entry) => ProductSales(
            productId: entry.key,
            productName: names[entry.key] ?? '',
            quantity: entry.value,
            revenue: revenues[entry.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return result.take(limit).toList();
  }
}
