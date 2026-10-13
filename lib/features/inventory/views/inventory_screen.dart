
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

  List<ProductModel> get filteredProducts {
    return controller.products.where((product) {
      final query = searchQuery.toLowerCase();

      return product.name.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  String formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = filteredProducts;

    final totalStock = controller.products.fold<int>(
      0,
      (sum, product) => sum + product.stock,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFD99AAF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inventaris Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5D9CB),
                  Color(0xFFEBC4D5),
                  Color(0xFFD8B8F0),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang!',
                  style: TextStyle(
                    color: Color(0xFF6D4C5A),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Kelola Inventaris Kamu',
                  style: TextStyle(
                    color: Color(0xFF493641),
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Total Produk',
                        '${controller.products.length}',
                        Icons.inventory_2_outlined,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _summaryCard(
                        'Total Stok',
                        '$totalStock',
                        Icons.warehouse_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Cari nama, ID, atau kategori...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFD99AAF),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFEADCE2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFD99AAF),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF493641),
                  ),
                ),

                Text(
                  '${products.length} produk',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text('Produk tidak ditemukan'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final lowStock = product.stock < 10;

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0x1AD99AAF),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),

                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                ),
                              ),
                            );
                          },

                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3DCE5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFFD99AAF),
                                    size: 29,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF493641),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        '${product.id} • ${product.category}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Text(
                                        formatPrice(product.price),
                                        style: const TextStyle(
                                          color: Color(0xFFB76E8B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: lowStock
                                              ? const Color(0xFFFFEBEE)
                                              : const Color(0xFFFCEAF1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Stok: ${product.stock}',
                                          style: TextStyle(
                                            color: lowStock
                                                ? Colors.red.shade700
                                                : const Color(0xFF9A5975),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFD0A6B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final product = await Navigator.push<ProductModel>(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          );

          if (!mounted) return;

          if (product != null) {
            setState(() {
              controller.products.add(product);
            });
          }
        },
        backgroundColor: const Color(0xFFD99AAF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF6D4C5A),
            size: 26,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6D4C5A),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF493641),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
