import 'package:flutter/material.dart';
import '../../../app/constants/app_color.dart';
import '../../../app/routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../inventory/views/inventory_screen.dart';
import 'home_screen.dart';
import '../../pos/views/pos_screen.dart';
import '../../pos/views/transaction_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _isLoading = true;
  int _currentIndex = 0;

  List<Widget> _screens = const [];
  List<BottomNavigationBarItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  /// Pastikan sesi dan role sudah tersedia sebelum tab dibangun.
  Future<void> _prepareSession() async {
    if (AuthController.currentUser == null) {
      await AuthController().restoreSession();
    } else {
      // Baca ulang profil agar perubahan role oleh admin langsung terpakai.
      await AuthController().refreshProfile();
    }

    if (!mounted) return;

    if (AuthController.currentUser == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      return;
    }

    if (AuthController.isAdmin) {
      // Admin melihat semua modul, mulai dari dashboard.
      _screens = [
        const HomeScreen(),
        PosScreen(),
        const TransactionHistoryScreen(),
        const InventoryScreen(),
      ];
      _items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Kasir',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Stok',
        ),
      ];
    } else {
      // Kasir langsung masuk ke POS; stok hanya bisa dilihat.
      _screens = [
        PosScreen(),
        const TransactionHistoryScreen(),
        const InventoryScreen(),
        const HomeScreen(),
      ];
      _items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Kasir',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Stok',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Akun',
        ),
      ];
    }

    setState(() {
      _currentIndex = 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColor.primary),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // 4 tab: paksa mode fixed agar label semua tab tetap terlihat.
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _items,
      ),
    );
  }
}
