import 'package:flutter/material.dart';
import 'payment_dialog.dart'; // 1. Import file payment_dialog di paling atas

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER POPUP ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Keranjang',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- DAFTAR ITEM KERANJANG ---
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildCartItem('Minyak Goreng 1L', 'Rp 18.500', 1),
                _buildCartItem('Mie Instan Goreng', 'Rp 6.000', 2),
                _buildCartItem('Gula Pasir 1kg', 'Rp 15.000', 1),
              ],
            ),
          ),

          const Divider(height: 32),

          // --- TOTAL PEMBAYARAN ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Total Pembayaran', style: TextStyle(fontSize: 16, color: Colors.black54)),
              Text('Rp 39.500', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // --- TOMBOL KODE YANG KAMU TANYAKAN DIPASANG DI SINI ---
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              // KODE ONPRESSED DI SINI:
              onPressed: () {
                Navigator.pop(context); // 1. Tutup keranjang dari bawah
                showDialog(
                  context: context,
                  builder: (context) => const PaymentDialog(), // 2. Buka dialog pembayaran
                );
              },
              child: const Text(
                'Lanjut ke Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Item Belanjaan
  Widget _buildCartItem(String title, String price, int qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(price, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _qtyButton(Icons.remove, () {}),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _qtyButton(Icons.add, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Colors.white,
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }
}