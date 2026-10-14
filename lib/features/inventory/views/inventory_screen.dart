
import 'package:flutter/material.dart';
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
  final InventoryController controller = InventoryController();
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

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

  List<ProductModel> get filteredProducts {
    return controller.products.where((product) {
      final query = searchQuery.toLowerCase();

      return product.name.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  int get totalStock {
    return controller.products.fold(
      0,
      (total, product) => total + product.stock,
    );
  }

  int get lowStockCount {
    return controller.products
        .where((product) => product.stock <= 5)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final products = filteredProducts;

    return Scaffold(
      backgroundColor: Colors.white,

      // Warna AppBar dibuat senada dengan bagian atas gradasi.
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

      // Satu gradasi untuk seluruh background halaman.
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
        child: Column(
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
                  const SizedBox(height: 18),

                  // Ringkasan inventaris
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: 'Jenis Produk',
                          value: controller.products.length.toString(),
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          title: 'Total Stok',
                          value: totalStock.toString(),
                          icon: Icons.warehouse_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          title: 'Stok Menipis',
                          value: lowStockCount.toString(),
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
                  fillColor: Colors.white.withOpacity(0.88),
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
                      color: Colors.white.withOpacity(0.8),
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
              child: products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: const Color(0xFFD99AAF)
                                  .withOpacity(0.7),
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
                            const Text(
                              'Coba gunakan kata kunci yang berbeda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFAA96A8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
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
                            color: Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailScreen(
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
                                        borderRadius:
                                            BorderRadius.circular(15),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLowStock
                                                ? const Color(0xFFFFE5E9)
                                                : const Color(0xFFF0E8FA),
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                    ),
            ),
          ],
        ),
      ),

      // Tombol tambah produk
      floatingActionButton: FloatingActionButton.extended(
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
        onPressed: () async {
          final newProduct = await Navigator.push<ProductModel>(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );

          if (newProduct != null) {
            setState(() {
              controller.products.add(newProduct);
            });
          }
        },
      ),
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
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD99AAF).withOpacity(0.08),
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
