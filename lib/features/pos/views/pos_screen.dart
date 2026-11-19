import 'package:flutter/material.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../inventory/models/product_model.dart';
import '../controllers/pos_controller.dart';
import 'receipt_screen.dart';
import 'widgets/cart_bottom_sheet.dart';
import 'widgets/product_card.dart';

/// Halaman kasir (POS). Dapat diakses oleh admin maupun kasir selama
/// pengguna sudah login.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  static const Color pastelPink = Color(0xFFFDE1E6);
  static const Color pastelLavender = Color(0xFFE9E5FA);
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);
  static const Color dangerMauve = Color(0xFFC45D78);

  final PosController _posController = PosController();
  final InventoryController _inventoryController = InventoryController();

  late Stream<List<ProductModel>> _productsStream;
  late final Stream<DashboardSummary> _summaryStream;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    final user = AuthController.currentUser;
    _productsStream = _inventoryController.getProductsStream();
    _summaryStream = DashboardController().getTodaySummary(
      isAdmin: AuthController.isAdmin,
      cashierId: user?.id ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _reloadProducts() {
    setState(() {
      _productsStream = _inventoryController.getProductsStream();
    });
  }

  List<String> _categoryOptions(List<ProductModel> products) {
    final categories = <String>{'Semua'};
    for (final product in products) {
      final category = product.category.trim();
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }
    return categories.toList();
  }

  List<ProductModel> _visibleProducts(
    List<ProductModel> products,
    String selectedCategory,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    return products.where((product) {
      final matchesCategory = selectedCategory == 'Semua' ||
          product.category.trim() == selectedCategory;
      final matchesQuery = query.isEmpty ||
          product.name.trim().toLowerCase().contains(query) ||
          product.category.trim().toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _addToCart(ProductModel product) {
    final error = _posController.addToCart(product);

    if (error != null) {
      _showMessage(error, dangerMauve);
      return;
    }

    setState(() {});
    _showMessage(
      '${product.name} ditambahkan ke keranjang.',
      const Color(0xFF8DAD96),
    );
  }

  Future<void> _openCart() async {
    if (_posController.cartItems.isEmpty) {
      _showMessage('Keranjang belanja masih kosong.', dangerMauve);
      return;
    }

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartBottomSheet(
        controller: _posController,
        onChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );

    if (!mounted) return;
    setState(() {});

    if (success == true) {
      _showMessage(
        'Transaksi berhasil disimpan. Stok produk sudah diperbarui.',
        const Color(0xFF8DAD96),
      );

      final receipt = _posController.lastCheckout;
      if (receipt != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptScreen(transaction: receipt),
          ),
        );
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _posController.cartItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
    final hasCart = _posController.cartItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              pastelPink,
              pastelLavender,
              Colors.white,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 15),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 15),
              Expanded(child: _buildCatalogSection()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentPink,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: _openCart,
        icon: Badge(
          isLabelVisible: cartCount > 0,
          backgroundColor: darkMauve,
          label: Text('$cartCount'),
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
          ),
        ),
        label: Text(
          hasCart
              ? 'Keranjang • ${CurrencyFormatter.formatRupiah(_posController.finalTotal)}'
              : 'Keranjang Kosong',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    final user = AuthController.currentUser;
    final roleLabel = AuthController.isAdmin ? 'Admin' : 'Kasir';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toko Sederhana • $roleLabel',
                  style: const TextStyle(
                    fontSize: 14,
                    color: mutedMauve,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.name ?? 'Kasir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkMauve,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: accentPink.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront,
              color: accentPink,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentPink,
              Color(0xFFBCA6D9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentPink.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Transaksi Hari Ini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<DashboardSummary>(
                    stream: _summaryStream,
                    builder: (context, snapshot) {
                      final summary = snapshot.data;
                      final value = snapshot.hasError
                          ? 'Tidak tersedia'
                          : summary == null
                              ? 'Memuat...'
                              : '${summary.transactionCount} Struk';

                      return Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 27,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEADCE8),
          ),
          boxShadow: [
            BoxShadow(
              color: accentPink.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari barang...',
            hintStyle: const TextStyle(
              color: Color(0xFFAA96A8),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: accentPink,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: accentPink,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogSection() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: accentPink),
          );
        }

        if (snapshot.hasError) {
          return _buildStatus(
            icon: Icons.cloud_off_rounded,
            title: 'Gagal memuat produk',
            subtitle: '${snapshot.error}',
            action: OutlinedButton.icon(
              onPressed: _reloadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB76E8B),
                side: const BorderSide(color: accentPink),
              ),
            ),
          );
        }

        final allProducts = snapshot.data ?? const <ProductModel>[];
        final options = _categoryOptions(allProducts);
        final selected = options.contains(_selectedCategory)
            ? _selectedCategory
            : 'Semua';
        final products = _visibleProducts(allProducts, selected);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var index = 0; index < options.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    _categoryChip(
                      options[index],
                      options[index] == selected,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: products.isEmpty
                  ? _buildStatus(
                      icon: Icons.inventory_2_outlined,
                      title: allProducts.isEmpty
                          ? 'Belum ada produk'
                          : 'Produk tidak ditemukan',
                      subtitle: allProducts.isEmpty
                          ? 'Admin perlu menambahkan produk di menu Stok.'
                          : 'Coba gunakan kata kunci atau kategori lain.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return ProductCard(
                          product: product,
                          onAdd: () => _addToCart(product),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryChip(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentPink
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? accentPink
                : const Color(0xFFEADCE8),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: accentPink.withValues(alpha: 0.06),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : mutedMauve,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: accentPink.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mutedMauve,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFAA96A8),
                fontSize: 12,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              action,
            ],
          ],
        ),
      ),
    );
  }
}