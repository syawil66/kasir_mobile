
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
      backgroundColor: Colors.white,
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

              // Daftar produk
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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

      // Tombol keranjang
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD99AAF),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CartBottomSheet(),
          );
        },
        icon: const Icon(
          Icons.shopping_cart_outlined,
          color: Colors.white,
        ),
        label: const Text(
          'Keranjang: Rp 39.500',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // Header kasir
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toko Sederhana',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF806B80),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kasir Utama',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF594455),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD99AAF).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront,
              color: Color(0xFFD99AAF),
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  // Kartu ringkasan transaksi
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
              Color(0xFFD99AAF),
              Color(0xFFBCA6D9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD99AAF).withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Transaksi Shift Ini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '24 Struk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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

  // Bar pencarian dan scan
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEADCE8),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD99AAF).withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Cari barang atau scan...',
            hintStyle: TextStyle(
              color: Color(0xFFAA96A8),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFFD99AAF),
            ),
            suffixIcon: Icon(
              Icons.qr_code_scanner,
              color: Color(0xFFD99AAF),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // Filter kategori
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

  // Desain chip kategori
  Widget _categoryChip(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFD99AAF)
            : Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFD99AAF)
              : const Color(0xFFEADCE8),
        ),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: const Color(0xFFD99AAF).withOpacity(0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : const Color(0xFF806B80),
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
