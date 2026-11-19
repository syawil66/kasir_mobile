import 'package:flutter/material.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../app/routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../inventory/models/product_model.dart';
import '../../pos/models/transaction_models.dart';
import '../controllers/dashboard_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color pastelPink = Color(0xFFFDE1E6);
  static const Color pastelLavender = Color(0xFFE9E5FA);
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);

  final InventoryController _inventoryController = InventoryController();
  final DashboardController _dashboardController = DashboardController();

  late final Stream<DashboardSummary> _summaryStream;
  late final Stream<List<ProductModel>> _productsStream;
  late final Stream<List<TransactionModel>> _recentTransactionsStream;

  @override
  void initState() {
    super.initState();
    _summaryStream = _dashboardController.getTodaySummary();
    _productsStream = _inventoryController.getProductsStream();
    _recentTransactionsStream = _dashboardController.getRecentTransactions();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari Aplikasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Akhiri sesi Firebase sebelum kembali ke halaman login.
    await AuthController().logout();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthController.currentUser;
    final isAdmin = AuthController.isAdmin;

    return Scaffold(
      backgroundColor: pastelPink,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Dashboard Toko' : 'Akun Kasir',
          style: const TextStyle(
            color: darkMauve,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: pastelPink,
        foregroundColor: darkMauve,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDE1E6),
              Color(0xFFE9E5FA),
              Colors.white,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(user, isAdmin),
              const SizedBox(height: 22),
              if (isAdmin)
                _buildAdminContent()
              else
                _buildKasirContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Hari Ini',
          style: TextStyle(
            color: darkMauve,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<DashboardSummary>(
          stream: _summaryStream,
          builder: (context, snapshot) {
            final summary = snapshot.data;
            final hasError = snapshot.hasError;
            final revenueValue = hasError
                ? 'Tidak tersedia'
                : summary == null
                    ? 'Memuat...'
                    : CurrencyFormatter.formatRupiah(summary.revenue);
            final countValue = hasError
                ? 'Tidak tersedia'
                : summary == null
                    ? 'Memuat...'
                    : '${summary.transactionCount} Nota';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Omzet',
                    value: revenueValue,
                    icon: Icons.monetization_on_rounded,
                    iconColor: accentPink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Transaksi',
                    value: countValue,
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF9C8AC4),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ProductModel>>(
          stream: _productsStream,
          builder: (context, snapshot) {
            final products = snapshot.data;
            final value = snapshot.hasError
                ? 'Tidak tersedia'
                : products == null
                    ? 'Memuat...'
                    : '${products.where((product) => product.stock <= 5).length} '
                        'Barang Perlu Ditambah';

            return _buildSummaryCard(
              title: 'Stok Menipis',
              value: value,
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFD6A15D),
              isHorizontal: true,
            );
          },
        ),
        const SizedBox(height: 26),
        const Text(
          'Aktivitas Terakhir',
          style: TextStyle(
            color: darkMauve,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _buildRecentTransactions(),
      ],
    );
  }

  Widget _buildKasirContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Kasir',
          style: TextStyle(
            color: darkMauve,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<DashboardSummary>(
          stream: _summaryStream,
          builder: (context, snapshot) {
            final summary = snapshot.data;
            final value = snapshot.hasError
                ? 'Tidak tersedia'
                : summary == null
                    ? 'Memuat...'
                    : '${summary.transactionCount} Nota';

            return _buildSummaryCard(
              title: 'Transaksi Hari Ini',
              value: value,
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF9C8AC4),
              isHorizontal: true,
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0DCE8)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: mutedMauve,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Omzet dan laporan keuangan toko hanya dapat dilihat oleh admin. '
                  'Hubungi admin jika membutuhkan informasi tersebut.',
                  style: TextStyle(
                    color: mutedMauve,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB76E8B),
              side: const BorderSide(color: accentPink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(UserModel? user, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
        boxShadow: [
          BoxShadow(
            color: darkMauve.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: pastelLavender,
            child: const Icon(
              Icons.person_outline_rounded,
              color: darkMauve,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Pengguna',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkMauve,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user?.username ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedMauve,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFFF3DCE8)
                  : const Color(0xFFE7E0F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin ? 'Admin' : 'Kasir',
              style: TextStyle(
                color: isAdmin
                    ? const Color(0xFFB76E8B)
                    : const Color(0xFF8063A0),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _recentTransactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0DCE8)),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: accentPink,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyActivity(
            'Aktivitas tidak dapat dimuat.',
            'Periksa koneksi atau aturan akses Firestore.',
          );
        }

        final transactions = snapshot.data ?? const <TransactionModel>[];
        if (transactions.isEmpty) {
          return _buildEmptyActivity(
            'Belum ada transaksi',
            'Transaksi yang tersimpan akan muncul di sini.',
          );
        }

        return Column(
          children: transactions
              .map((transaction) => _buildTransactionTile(transaction))
              .toList(),
        );
      },
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final shortId = transaction.id.length > 6
        ? transaction.id.substring(0, 6).toUpperCase()
        : transaction.id.toUpperCase();
    final itemCount = transaction.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
    final itemNames = transaction.items
        .map((item) => item.product.name)
        .where((name) => name.isNotEmpty)
        .take(2)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: const CircleAvatar(
          backgroundColor: pastelLavender,
          child: Icon(
            Icons.shopping_bag_rounded,
            color: darkMauve,
          ),
        ),
        title: Text(
          'Transaksi #$shortId',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: darkMauve,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          itemNames.isEmpty
              ? '$itemCount Item'
              : '$itemCount Item • $itemNames',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: mutedMauve,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          CurrencyFormatter.formatRupiah(transaction.totalAmount),
          style: const TextStyle(
            color: darkMauve,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivity(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: accentPink,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkMauve,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedMauve,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isHorizontal = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF0DCE8),
        ),
        boxShadow: [
          BoxShadow(
            color: darkMauve.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isHorizontal
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: mutedMauve,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        style: const TextStyle(
                          color: darkMauve,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: mutedMauve,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: darkMauve,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
    );
  }
}
