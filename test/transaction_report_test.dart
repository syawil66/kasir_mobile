import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_app/features/inventory/models/product_model.dart';
import 'package:kasir_app/features/pos/controllers/transaction_controller.dart';
import 'package:kasir_app/features/pos/models/transaction_models.dart';
import 'package:kasir_app/features/pos/views/receipt_screen.dart';
import 'package:kasir_app/shared/utils/date_formatter.dart';

CartItemModel item({
  required String id,
  required String name,
  required double price,
  required int quantity,
}) {
  return CartItemModel(
    product: ProductModel(
      id: id,
      name: name,
      price: price,
      stock: 10,
      category: 'Minuman',
      updatedAt: null,
    ),
    quantity: quantity,
  );
}

TransactionModel transaction({
  required String id,
  required List<CartItemModel> items,
  double discount = 0,
  bool voided = false,
  String cashierId = 'kasir1',
}) {
  final subtotal = items.fold<double>(0, (total, item) => total + item.totalPrice);

  return TransactionModel(
    id: id,
    items: items,
    subtotal: subtotal,
    discount: discount,
    finalTotal: subtotal - discount,
    cashPaid: subtotal - discount,
    changeAmount: 0,
    cashierId: cashierId,
    cashierName: 'Kasir Satu',
    createdAt: DateTime(2026, 11, 19, 10, 30),
    voided: voided,
  );
}

void main() {
  group('SalesReport', () {
    test('menjumlahkan omzet dan item dari nota aktif', () {
      final report = SalesReport.fromTransactions([
        transaction(
          id: 't1',
          items: [item(id: 'p1', name: 'Kopi', price: 10000, quantity: 2)],
        ),
        transaction(
          id: 't2',
          items: [item(id: 'p2', name: 'Teh', price: 5000, quantity: 3)],
          discount: 2000,
        ),
      ]);

      expect(report.transactionCount, 2);
      expect(report.itemCount, 5);
      expect(report.revenue, 20000 + 13000);
      expect(report.discountTotal, 2000);
      expect(report.voidedCount, 0);
      expect(report.averagePerTransaction, 16500);
    });

    test('nota dibatalkan tidak dihitung ke omzet', () {
      final report = SalesReport.fromTransactions([
        transaction(
          id: 't1',
          items: [item(id: 'p1', name: 'Kopi', price: 10000, quantity: 1)],
        ),
        transaction(
          id: 't2',
          items: [item(id: 'p1', name: 'Kopi', price: 10000, quantity: 5)],
          voided: true,
        ),
      ]);

      expect(report.transactionCount, 1);
      expect(report.revenue, 10000);
      expect(report.itemCount, 1);
      expect(report.voidedCount, 1);
    });

    test('daftar kosong menghasilkan laporan nol', () {
      final report = SalesReport.fromTransactions(const []);
      expect(report.transactionCount, 0);
      expect(report.revenue, 0);
      expect(report.averagePerTransaction, 0);
    });
  });

  group('TransactionController.topProducts', () {
    test('menggabungkan qty produk yang sama dan mengurutkan terlaris', () {
      final products = TransactionController.topProducts([
        transaction(
          id: 't1',
          items: [
            item(id: 'p1', name: 'Kopi', price: 10000, quantity: 2),
            item(id: 'p2', name: 'Teh', price: 5000, quantity: 1),
          ],
        ),
        transaction(
          id: 't2',
          items: [item(id: 'p1', name: 'Kopi', price: 10000, quantity: 3)],
        ),
      ]);

      expect(products.length, 2);
      expect(products.first.productId, 'p1');
      expect(products.first.quantity, 5);
      expect(products.first.revenue, 50000);
      expect(products.last.productId, 'p2');
    });

    test('produk dari nota dibatalkan tidak dihitung', () {
      final products = TransactionController.topProducts([
        transaction(
          id: 't1',
          items: [item(id: 'p1', name: 'Kopi', price: 10000, quantity: 2)],
          voided: true,
        ),
      ]);

      expect(products, isEmpty);
    });
  });

  group('TransactionModel.fromMap', () {
    test('membaca field pembatalan', () {
      final model = TransactionModel.fromMap({
        'items': const [],
        'subtotal': 10000,
        'discount': 0,
        'finalTotal': 10000,
        'cashPaid': 10000,
        'changeAmount': 0,
        'cashierId': 'kasir1',
        'cashierName': 'Kasir Satu',
        'voided': true,
        'voidedBy': 'admin1',
      }, 'tx-1');

      expect(model.voided, isTrue);
      expect(model.voidedBy, 'admin1');
      expect(model.itemCount, 0);
    });

    test('nota lama tanpa field voided dianggap aktif', () {
      final model = TransactionModel.fromMap({
        'items': const [],
        'subtotal': 1000,
        'discount': 0,
        'finalTotal': 1000,
        'cashPaid': 1000,
        'changeAmount': 0,
        'cashierId': 'kasir1',
        'cashierName': 'Kasir Satu',
      }, 'tx-2');

      expect(model.voided, isFalse);
      expect(model.voidedAt, isNull);
    });
  });

  group('DateFormatter', () {
    test('format tanggal Bahasa Indonesia', () {
      final date = DateTime(2026, 11, 19, 14, 5);
      expect(DateFormatter.formatDate(date), '19 November 2026');
      expect(DateFormatter.formatTime(date), '14:05');
      expect(DateFormatter.formatDateTime(date), '19 November 2026, 14:05');
    });

    test('startOfDay membuang jam', () {
      expect(
        DateFormatter.startOfDay(DateTime(2026, 11, 19, 23, 59)),
        DateTime(2026, 11, 19),
      );
    });
  });

  group('ReceiptScreen', () {
    testWidgets('menampilkan item, total, dan kembalian', (tester) async {
      final nota = transaction(
        id: 'abcdef123456',
        items: [item(id: 'p1', name: 'Kopi Susu', price: 10000, quantity: 2)],
        discount: 2000,
      );

      await tester.pumpWidget(
        MaterialApp(home: ReceiptScreen(transaction: nota)),
      );

      expect(find.text('Kopi Susu'), findsOneWidget);
      expect(find.text('2 x Rp 10.000'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsWidgets); // subtotal
      expect(find.text('- Rp 2.000'), findsOneWidget); // diskon
      expect(find.text('Rp 18.000'), findsWidgets); // total
    });

    testWidgets('menandai nota yang dibatalkan', (tester) async {
      final nota = transaction(
        id: 'tx-void',
        items: [item(id: 'p1', name: 'Teh', price: 5000, quantity: 1)],
        voided: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: ReceiptScreen(transaction: nota)),
      );

      expect(find.text('Nota ini dibatalkan.'), findsOneWidget);
    });
  });
}
