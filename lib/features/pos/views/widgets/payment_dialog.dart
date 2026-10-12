import 'package:flutter/material.dart';

class PaymentDialog extends StatelessWidget {
  const PaymentDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Total Tagihan',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rp 39.500',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Pilihan Metode Pembayaran
            Row(
              children: [
                Expanded(
                  child: _buildMethodCard(
                    icon: Icons.money,
                    label: 'Tunai',
                    isSelected: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMethodCard(
                    icon: Icons.qr_code,
                    label: 'QRIS',
                    isSelected: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input Uang Diterima
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Uang Diterima',
                hintText: 'Rp 50.000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Selesai
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Selesaikan Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}