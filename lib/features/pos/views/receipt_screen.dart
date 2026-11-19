import 'package:flutter/material.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../models/transaction_models.dart';

/// Struk nota: ditampilkan setelah checkout dan saat membuka riwayat.
class ReceiptScreen extends StatelessWidget {
  final TransactionModel transaction;

  const ReceiptScreen({
    super.key,
    required this.transaction,
  });

  static const Color pastelPink = Color(0xFFFDE1E6);
  static const Color pastelLavender = Color(0xFFE9E5FA);
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);
  static const Color dangerMauve = Color(0xFFC45D78);

  String get _shortId => transaction.id.length > 8
      ? transaction.id.substring(0, 8).toUpperCase()
      : transaction.id.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Struk Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: pastelPink,
        foregroundColor: darkMauve,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pastelPink, pastelLavender, Colors.white],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0DCE8)),
                  boxShadow: [
                    BoxShadow(
                      color: darkMauve.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: accentPink,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toko Sederhana',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkMauve,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nota Penjualan',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: mutedMauve),
                    ),
                    const SizedBox(height: 14),
                    _dashedDivider(),
                    const SizedBox(height: 12),
                    _infoRow('No. Nota', '#$_shortId'),
                    _infoRow(
                      'Tanggal',
                      DateFormatter.formatDateTime(transaction.createdAt),
                    ),
                    _infoRow('Kasir', transaction.cashierName),
                    _infoRow('Pembayaran', transaction.paymentMethod),
                    const SizedBox(height: 12),
                    _dashedDivider(),
                    const SizedBox(height: 12),
                    ...transaction.items.map(_buildItemRow),
                    const SizedBox(height: 12),
                    _dashedDivider(),
                    const SizedBox(height: 12),
                    _amountRow(
                      'Subtotal',
                      CurrencyFormatter.formatRupiah(transaction.subtotal),
                    ),
                    if (transaction.discount > 0)
                      _amountRow(
                        _discountLabel,
                        '- ${CurrencyFormatter.formatRupiah(transaction.discount)}',
                        valueColor: dangerMauve,
                      ),
                    const SizedBox(height: 6),
                    _amountRow(
                      'Total',
                      CurrencyFormatter.formatRupiah(transaction.finalTotal),
                      isBold: true,
                    ),
                    _amountRow(
                      'Tunai',
                      CurrencyFormatter.formatRupiah(transaction.cashPaid),
                    ),
                    _amountRow(
                      'Kembalian',
                      CurrencyFormatter.formatRupiah(transaction.changeAmount),
                    ),
                    if (transaction.voided) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8EC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              color: dangerMauve,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                transaction.voidedAt == null
                                    ? 'Nota ini dibatalkan.'
                                    : 'Nota dibatalkan pada '
                                        '${DateFormatter.formatDateTime(transaction.voidedAt!)}.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: dangerMauve,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Terima kasih telah berbelanja.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: mutedMauve),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _discountLabel {
    if (transaction.discountMode != 'percentage') return 'Diskon';
    return 'Diskon (${transaction.discountInput.toStringAsFixed(0)}%)';
  }

  Widget _buildItemRow(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name.isEmpty ? 'Produk' : item.product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkMauve,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} x '
                  '${CurrencyFormatter.formatRupiah(item.product.price)}',
                  style: const TextStyle(fontSize: 11, color: mutedMauve),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.formatRupiah(item.totalPrice),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: darkMauve,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: mutedMauve),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkMauve,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? darkMauve : mutedMauve,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? darkMauve,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0DCE8),
    );
  }
}
