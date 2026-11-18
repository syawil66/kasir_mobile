import 'package:flutter/material.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final InventoryController _controller = InventoryController();

  late ProductModel _product;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  String formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}';
  }

  Future<void> _editProduct() async {
    if (!AuthController.isAdmin || _isDeleting) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: _product),
      ),
    );

    if (!mounted || saved != true) return;

    final refreshed = await _controller.getProduct(_product.id);
    if (!mounted || refreshed == null) return;

    setState(() {
      _product = refreshed;
    });
  }

  Future<void> _deleteProduct() async {
    if (!AuthController.isAdmin || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Yakin ingin menghapus "${_product.name}"? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC45D78),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final error = await _controller.deleteProduct(_product.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFB86B80),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = _product.stock <= 5;
    final bool isAdmin = AuthController.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFDE1E6),
        foregroundColor: const Color(0xFF594455),
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD99AAF)
                            .withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Color(0xFFD99AAF),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD99AAF)
                          .withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMASI PRODUK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFFB76E8B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF594455),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3DCE8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _product.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB76E8B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _detailRow(
                      icon: Icons.qr_code_rounded,
                      label: 'ID Produk',
                      value: _product.id,
                    ),
                    const Divider(
                      height: 28,
                      color: Color(0xFFF0E5EC),
                    ),
                    _detailRow(
                      icon: Icons.category_outlined,
                      label: 'Kategori',
                      value: _product.category,
                    ),
                    const Divider(
                      height: 28,
                      color: Color(0xFFF0E5EC),
                    ),
                    _detailRow(
                      icon: Icons.payments_outlined,
                      label: 'Harga',
                      value: formatPrice(_product.price),
                      valueColor: const Color(0xFFB76E8B),
                    ),
                    const Divider(
                      height: 28,
                      color: Color(0xFFF0E5EC),
                    ),
                    _detailRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stok Produk',
                      value: '${_product.stock} unit',
                      valueColor: isLowStock
                          ? const Color(0xFFC45D78)
                          : const Color(0xFF8063A0),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? const Color(0xFFFFE8EC)
                            : const Color(0xFFF0E8FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLowStock
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: isLowStock
                                ? const Color(0xFFC45D78)
                                : const Color(0xFF8063A0),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isLowStock
                                  ? 'Stok produk menipis, perlu diperiksa.'
                                  : 'Stok produk tersedia.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLowStock
                                    ? const Color(0xFFC45D78)
                                    : const Color(0xFF8063A0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Aksi admin: ubah dan hapus produk
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _editProduct,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB76E8B),
                            side: const BorderSide(
                              color: Color(0xFFD99AAF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isDeleting ? null : _deleteProduct,
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 18),
                          label: Text(
                            _isDeleting ? 'Menghapus...' : 'Hapus',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC45D78),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFC45D78)
                                    .withValues(alpha: 0.6),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text(
                    'Kembali ke Inventaris',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD99AAF),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF9EAF0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD99AAF),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAA96A8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF594455),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
