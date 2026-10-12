import 'package:flutter/material.dart';
import 'widgets/product_card.dart';
import 'widgets/cart_bottom_sheet.dart';

class PosScreen extends StatelessWidget {
  PosScreen({Key? key}) : super(key: key);

  // Data dummy produk Toko Sederhana
  final List<Map<String, dynamic>> products = [
    {'name': 'Minyak Goreng 1L', 'price': 'Rp 18.500'},
    {'name': 'Beras Premium 5kg', 'price': 'Rp 75.000'},
    {'name': 'Mie Instan Goreng', 'price': 'Rp 3.000'},
    {'name': 'Gula Pasir 1kg', 'price': 'Rp 15.000'},
    {'name': 'Kopi Sachet', 'price': 'Rp 1.500'},
    {'name': 'Sabun Mandi', 'price': 'Rp 4.500'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDE1E6), // Pink lembut dari gambar referensi
              Color(0xFFE9E5FA), // Ungu kebiruan lembut
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7],
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
              _buildCategoryFilters(),
              const SizedBox(height: 15),
              // Area Daftar Produk
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        name: products[index]['name'],
                        price: products[index]['price'],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Tombol Floating Keranjang di Bawah
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E1E1E), // Hitam gelap
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          // Buka Popup Keranjang
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            builder: (context) => const CartBottomSheet(),
          );
        },
        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
        label: const Text(
          'Keranjang: Rp 39.500',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Header Sapaan Kasir
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Toko Sederhana', style: TextStyle(fontSize: 16, color: Colors.black54)),
              Text('Kasir Utama', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 24,
            child: Icon(Icons.storefront, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  // Kartu Hitam Ringkasan
  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Total Transaksi Shift Ini', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 8),
                Text('24 Struk', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  // Bar Pencarian & Scan
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Cari barang atau scan...',
            hintStyle: TextStyle(color: Colors.black38),
            prefixIcon: Icon(Icons.search, color: Colors.black54),
            suffixIcon: Icon(Icons.qr_code_scanner, color: Colors.black54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // Filter Kategori
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _categoryChip('Semua', true),
          const SizedBox(width: 10),
          _categoryChip('Sembako', false),
          const SizedBox(width: 10),
          _categoryChip('Minuman', false),
          const SizedBox(width: 10),
          _categoryChip('Snack', false),
          const SizedBox(width: 10),
          _categoryChip('Lainnya', false),
        ],
      ),
    );
  }

  Widget _categoryChip(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFC7D388) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.black54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}