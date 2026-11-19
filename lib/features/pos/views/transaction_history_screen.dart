import 'package:flutter/material.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_models.dart';
import 'receipt_screen.dart';

/// Riwayat nota. Admin melihat semua transaksi dan bisa membatalkan nota;
/// kasir hanya melihat notanya sendiri tanpa nominal omzet toko.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

enum _HistoryRange { today, week, month, all }

extension on _HistoryRange {
  String get label {
    switch (this) {
      case _HistoryRange.today:
        return 'Hari Ini';
      case _HistoryRange.week:
        return '7 Hari';
      case _HistoryRange.month:
        return '30 Hari';
      case _HistoryRange.all:
        return 'Semua';
    }
  }

  DateTime? get start {
    final now = DateTime.now();
    final today = DateFormatter.startOfDay(now);
    switch (this) {
      case _HistoryRange.today:
        return today;
      case _HistoryRange.week:
        return today.subtract(const Duration(days: 6));
      case _HistoryRange.month:
        return today.subtract(const Duration(days: 29));
      case _HistoryRange.all:
        return null;
    }
  }

  DateTime? get end {
    if (this == _HistoryRange.all) return null;
    final today = DateFormatter.startOfDay(DateTime.now());
    return today.add(const Duration(days: 1));
  }
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const Color pastelPink = Color(0xFFFDE1E6);
  static const Color pastelLavender = Color(0xFFE9E5FA);
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);
  static const Color dangerMauve = Color(0xFFC45D78);

  final TransactionController _controller = TransactionController();
  final TextEditingController _searchController = TextEditingController();

  _HistoryRange _range = _HistoryRange.today;
  String _searchQuery = '';
  late Stream<List<TransactionModel>> _transactionsStream;
  String? _voidingId;

  @override
  void initState() {
    super.initState();
    _transactionsStream = _buildStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<TransactionModel>> _buildStream() {
    return _controller.getTransactions(
      isAdmin: AuthController.isAdmin,
      cashierId: AuthController.currentUser?.id ?? '',
      start: _range.start,
      end: _range.end,
    );
  }

  void _reload() {
    setState(() {
      _transactionsStream = _buildStream();
    });
  }

  void _changeRange(_HistoryRange range) {
    if (_range == range) return;
    setState(() {
      _range = range;
      _transactionsStream = _buildStream();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFB86B80) : const Color(0xFF7C9A7E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  List<TransactionModel> _filtered(List<TransactionModel> transactions) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return transactions;

    return transactions.where((transaction) {
      return transaction.id.toLowerCase().contains(query) ||
          transaction.cashierName.toLowerCase().contains(query) ||
          transaction.items.any(
            (item) => item.product.name.toLowerCase().contains(query),
          );
    }).toList();
  }

  Future<void> _openReceipt(TransactionModel transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(transaction: transaction),
      ),
    );
  }

  Future<void> _confirmVoid(TransactionModel transaction) async {
    if (!AuthController.isAdmin || _voidingId != null || transaction.voided) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Nota'),
        content: Text(
          'Batalkan nota #${transaction.id.toUpperCase()}?\n\n'
          'Stok produk pada nota ini akan dikembalikan dan nota tidak lagi '
          'dihitung ke omzet. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: dangerMauve),
            child: const Text('Batalkan Nota'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _voidingId = transaction.id);
    final error = await _controller.voidTransaction(transaction.id);
    if (!mounted) return;
    setState(() => _voidingId = null);

    _showMessage(
      error ?? 'Nota berhasil dibatalkan dan stok sudah dikembalikan.',
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthController.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: pastelPink,
        foregroundColor: darkMauve,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final range in _HistoryRange.values) ...[
                      if (range != _HistoryRange.values.first)
                        const SizedBox(width: 8),
                      _rangeChip(range),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Cari no. nota, kasir, atau produk...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAA96A8),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: accentPink),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: accentPink),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEADCE8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: accentPink, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _transactionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: accentPink),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildStatus(
                      icon: Icons.cloud_off_rounded,
                      title: 'Gagal memuat riwayat',
                      subtitle: '${snapshot.error}',
                      action: OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB76E8B),
                          side: const BorderSide(color: accentPink),
                        ),
                      ),
                    );
                  }

                  final all = snapshot.data ?? const <TransactionModel>[];
                  final transactions = _filtered(all);
                  final report = SalesReport.fromTransactions(all);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _buildReportCard(report, isAdmin: isAdmin),
                      const SizedBox(height: 16),
                      if (transactions.isEmpty)
                        _buildStatus(
                          icon: Icons.receipt_long_outlined,
                          title: all.isEmpty
                              ? 'Belum ada transaksi'
                              : 'Transaksi tidak ditemukan',
                          subtitle: all.isEmpty
                              ? 'Nota yang tersimpan akan muncul di sini.'
                              : 'Coba kata kunci atau rentang tanggal lain.',
                        )
                      else
                        ...transactions.map(
                          (transaction) => _buildTransactionTile(transaction),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(_HistoryRange range) {
    final isSelected = _range == range;
    return GestureDetector(
      onTap: () => _changeRange(range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? accentPink : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? accentPink : const Color(0xFFEADCE8),
          ),
        ),
        child: Text(
          range.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : mutedMauve,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(SalesReport report, {required bool isAdmin}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentPink, Color(0xFFBCA6D9)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentPink.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Omzet ${_range.label}' : 'Nota ${_range.label}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? CurrencyFormatter.formatRupiah(report.revenue)
                : '${report.transactionCount} Nota',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _reportStat('Nota', '${report.transactionCount}'),
              _reportStat('Item', '${report.itemCount}'),
              if (isAdmin)
                _reportStat(
                  'Diskon',
                  CurrencyFormatter.formatRupiah(report.discountTotal),
                ),
              if (report.voidedCount > 0)
                _reportStat('Dibatalkan', '${report.voidedCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final shortId = transaction.id.length > 6
        ? transaction.id.substring(0, 6).toUpperCase()
        : transaction.id.toUpperCase();
    final itemNames = transaction.items
        .map((item) => item.product.name)
        .where((name) => name.isNotEmpty)
        .take(2)
        .join(', ');
    final isVoiding = _voidingId == transaction.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        onTap: () => _openReceipt(transaction),
        leading: CircleAvatar(
          backgroundColor: transaction.voided
              ? const Color(0xFFFFE8EC)
              : pastelLavender,
          child: Icon(
            transaction.voided
                ? Icons.cancel_outlined
                : Icons.shopping_bag_rounded,
            color: transaction.voided ? dangerMauve : darkMauve,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Nota #$shortId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: transaction.voided ? mutedMauve : darkMauve,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration:
                      transaction.voided ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (transaction.voided) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Dibatalkan',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: dangerMauve,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${DateFormatter.formatDateTime(transaction.createdAt)} • '
          '${transaction.cashierName}'
          '${itemNames.isEmpty ? '' : ' • $itemNames'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: mutedMauve, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatRupiah(transaction.finalTotal),
              style: TextStyle(
                color: transaction.voided ? mutedMauve : darkMauve,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (AuthController.isAdmin && !transaction.voided)
              PopupMenuButton<String>(
                tooltip: 'Aksi nota',
                enabled: !isVoiding,
                icon: isVoiding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: dangerMauve,
                        ),
                      )
                    : const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: mutedMauve,
                      ),
                onSelected: (value) {
                  if (value == 'void') _confirmVoid(transaction);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'void',
                    child: Text(
                      'Batalkan nota',
                      style: TextStyle(fontSize: 13, color: dangerMauve),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: accentPink.withValues(alpha: 0.8)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkMauve,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedMauve, fontSize: 12),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }
}
