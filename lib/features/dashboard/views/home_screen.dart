import 'package:flutter/material.dart';
import '../../../app/constants/app_color.dart';
import '../../../app/constants/app_text_styles.dart';
import '../../../shared/utils/currency_formatter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD5B5), // Peach lembut (atas)
              Color(0xFFFDE1E6), // Pink lembut (tengah)
              Colors.white,       // Putih bersih (bawah)
            ],
            stops: [0.0, 0.35, 0.8],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                
                // Hero Text Judul Dashboard
                const Text(
                  'Let\'s Make\nToday Productive',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 20),

                // Kartu Hitam Ringkasan Performa Shift
                _buildDarkSummaryCard(),
                const SizedBox(height: 24),

                // Status Filter Badges / Quick Pills
                _buildQuickFilters(),
                const SizedBox(height: 24),

                // Header Seksi Aktivitas Terakhir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Aktivitas Terakhir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Daftar Kartu Aktivitas Transaksi
                _buildActivityCard(
                  trxId: 'TRX-001',
                  items: '2 Item • Kopi Susu Aren, Roti Bakar',
                  price: CurrencyFormatter.formatRupiah(33000),
                  time: '10:30 WIB',
                  status: 'Selesai',
                ),
                const SizedBox(height: 12),
                _buildActivityCard(
                  trxId: 'TRX-002',
                  items: '1 Item • Beras Premium 5kg',
                  price: CurrencyFormatter.formatRupiah(75000),
                  time: '09:45 WIB',
                  status: 'Selesai',
                ),
                const SizedBox(height: 80), // Jarak aman dari Bottom Navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Avatar + Sapaan + Action Buttons
  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(Icons.storefront, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Selamat Pagi',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              'Toko Sederhana',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Tombol Tambah (+) Hitam
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        const SizedBox(width: 8),
        // Tombol Lonceng Notifikasi Putih
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Color(0xFF1E1E1E), size: 20),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }

  // Kartu Hitam Ringkasan ("Today's Progress")
  Widget _buildDarkSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performa Shift Hari Ini',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Indikator Target Melingkar
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: 0.72,
                        strokeWidth: 9,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC7D388)),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '72%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Target',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Rincian Data Ringkasan
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow(
                      icon: Icons.monetization_on_outlined,
                      value: CurrencyFormatter.formatRupiah(1500000),
                      label: 'Penjualan',
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      icon: Icons.receipt_long_outlined,
                      value: '24 Nota',
                      label: 'Transaksi',
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      icon: Icons.warning_amber_rounded,
                      value: '3 Barang',
                      label: 'Stok Menipis',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC7D388), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Filter Status (Pills)
  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterBadge('24', 'Transaksi', isSelected: true),
          const SizedBox(width: 10),
          _buildFilterBadge('3', 'Stok Menipis', isSelected: false),
          const SizedBox(width: 10),
          _buildFilterBadge('Shift', 'Pagi', isSelected: false),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(String count, String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFC7D388) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }

  // Kartu Aktivitas Transaksi Modern
  Widget _buildActivityCard({
    required String trxId,
    required String items,
    required String price,
    required String time,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_outward, size: 16, color: Color(0xFF1E1E1E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Transaksi #$trxId',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            items,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}