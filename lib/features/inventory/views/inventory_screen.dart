import 'package:flutter/material.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryController _controller = InventoryController();
  final TextEditingController searchController = TextEditingController();

  late Stream<List<ProductModel>> _productsStream;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productsStream = _controller.getProductsStream();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}';
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products) {
    final query = searchQuery.toLowerCase();

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  int _totalStock(List<ProductModel> products) {
    return products.fold(
      0,
      (total, product) => total + product.stock,
    );
  }

  int _lowStockCount(List<ProductModel> products) {
    return products.where((product) => product.stock <= 5).length;
  }

  void _reload() {
    setState(() {
      _productsStream = _controller.getProductsStream();
    });
  }

  Future<void> _openAddForm() async {
    if (!AuthController.isAdmin) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthController.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDE1E6),
        foregroundColor: const Color(0xFF594455),
        elevation: 0,
        title: const Text(
          'Inventaris Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: StreamBuilder<List<ProductModel>>(
          stream: _productsStream,
          builder: (context, snapshot) {
            final allProducts = snapshot.data ?? const <ProductModel>[];
            final products = _filteredProducts(allProducts);
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return Column(
              children: [
                // Header halaman
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Produk',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF594455),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pantau stok dan data produk kamu di sini.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF806B80),
                        ),
                      ),
                      if (!isAdmin) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEADCE8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: Color(0xFFB76E8B),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mode kasir: data produk hanya dapat dilihat.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF806B80),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Ringkasan inventaris (selalu dari seluruh produk)
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              title: 'Jenis Produk',
                              value: allProducts.length.toString(),
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryCard(
                              title: 'Total Stok',
                              value: _totalStock(allProducts).toString(),
                              icon: Icons.warehouse_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryCard(
                              title: 'Stok Menipis',
                              value: _lowStockCount(allProducts).toString(),
                              icon: Icons.warning_amber_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pencarian produk
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama, ID, atau kategori produk...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFAA96A8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFD99AAF),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFFD99AAF),
                              ),
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.88),
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
                        borderSide: const BorderSide(
                          color: Color(0xFFEADCE8),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFD99AAF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Judul daftar produk
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Daftar Produk',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF594455),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${products.length} produk',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB76E8B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Daftar produk
                Expanded(
                  child: _buildProductList(
                    snapshot: snapshot,
                    products: products,
                    isLoading: isLoading,
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // Tombol tambah produk hanya untuk admin
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFD99AAF),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Produk',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _openAddForm,
            )
          : null,
    );
  }

  Widget _buildProductList({
    required AsyncSnapshot<List<ProductModel>> snapshot,
    required List<ProductModel> products,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD99AAF),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: const Color(0xFFD99AAF).withValues(alpha: 0.8),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF806B80),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFAA96A8),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB76E8B),
                  side: const BorderSide(color: Color(0xFFD99AAF)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: const Color(0xFFD99AAF).withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                searchQuery.isEmpty
                    ? 'Belum ada produk'
                    : 'Produk tidak ditemukan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF806B80),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                searchQuery.isEmpty
                    ? 'Tambahkan produk untuk mulai mengelola stok.'
                    : 'Coba gunakan kata kunci yang berbeda.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFAA96A8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        100,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isLowStock = product.stock <= 5;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product: product,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Ikon produk
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3DCE8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFD99AAF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Detail produk
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF594455),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'ID: ${product.id} • ${product.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFAA96A8),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            formatPrice(product.price),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB76E8B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Label stok
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? const Color(0xFFFFE5E9)
                                : const Color(0xFFF0E8FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Stok ${product.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLowStock
                                  ? const Color(0xFFC45D78)
                                  : const Color(0xFF8063A0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Color(0xFFD0B7C9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Kartu ringkasan inventaris
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD99AAF).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 23,
            color: const Color(0xFFB76E8B),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF594455),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF806B80),
            ),
          ),
        ],
      ),
    );
  }
}
