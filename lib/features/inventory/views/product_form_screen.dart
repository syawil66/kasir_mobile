import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  /// Jika diisi, form dipakai untuk mengubah produk yang sudah ada.
  final ProductModel? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const List<String> _defaultCategories = [
    'Sembako',
    'Minuman',
    'Snack',
    'Lainnya',
  ];

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final InventoryController _controller = InventoryController();

  late String selectedCategory;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  List<String> get _categories {
    final existing = widget.product?.category;
    if (existing == null ||
        existing.isEmpty ||
        _defaultCategories.contains(existing)) {
      return _defaultCategories;
    }
    return [..._defaultCategories, existing];
  }

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(0);
      stockController.text = product.stock.toString();
      selectedCategory = product.category.isEmpty
          ? _defaultCategories.first
          : product.category;
    } else {
      selectedCategory = _defaultCategories.first;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!AuthController.isAdmin || _isSaving) return;
    if (!formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = nameController.text.trim();
    final price = double.parse(priceController.text.trim());
    final stock = int.parse(stockController.text.trim());

    String? error;
    if (_isEditing) {
      error = await _controller.updateProduct(
        ProductModel(
          id: widget.product!.id,
          name: name,
          price: price,
          stock: stock,
          category: selectedCategory,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      error = await _controller.addProduct(
        name: name,
        category: selectedCategory,
        price: price,
        stock: stock,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

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

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthController.isAdmin) {
      return _buildAccessDenied();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
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
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Ubah Informasi Produk' : 'Informasi Produk',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF594455),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing
                      ? 'Perbarui data produk yang sudah terdaftar.'
                      : 'Masukkan informasi produk yang ingin ditambahkan.',
                  style: const TextStyle(
                    color: Color(0xFF806B80),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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
                      _fieldLabel('Nama Produk'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          'Masukkan nama produk',
                          Icons.shopping_bag_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _fieldLabel('Harga Produk (Rp)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          'Contoh: 15000',
                          Icons.payments_outlined,
                        ),
                        validator: (value) {
                          final price = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (price == null || price <= 0) {
                            return 'Harga harus lebih dari 0';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _fieldLabel('Jumlah Stok'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: stockController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          'Masukkan jumlah stok',
                          Icons.warehouse_outlined,
                        ),
                        validator: (value) {
                          final stock = int.tryParse(
                            value?.trim() ?? '',
                          );

                          if (stock == null || stock < 0) {
                            return 'Stok minimal 0 dan harus bilangan bulat';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _fieldLabel('Kategori Produk'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          'Pilih kategori',
                          Icons.category_outlined,
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedCategory = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProduct,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving
                                ? 'Menyimpan...'
                                : _isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Produk',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD99AAF),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFD99AAF)
                                    .withValues(alpha: 0.6),
                            disabledForegroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB76E8B),
                            side: const BorderSide(
                              color: Color(0xFFD99AAF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Akses Ditolak',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDE1E6),
        foregroundColor: const Color(0xFF594455),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Color(0xFFD99AAF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Khusus Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF594455),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hanya admin yang dapat menambah atau mengubah produk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF806B80),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB76E8B),
                  side: const BorderSide(color: Color(0xFFD99AAF)),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF594455),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAA96A8),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFD99AAF),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEADCE8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEADCE8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFD99AAF),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFC45D78),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFC45D78),
          width: 1.5,
        ),
      ),
    );
  }
}
