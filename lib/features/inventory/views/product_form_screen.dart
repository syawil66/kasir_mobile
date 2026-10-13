
import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  String selectedCategory = 'Kategori 1';

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  void saveProduct() {
    if (!formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: 'PRD${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      price: double.parse(priceController.text.trim()),
      stock: int.parse(stockController.text.trim()),
      category: selectedCategory,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar dengan warna pink muda
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFDE1E6),
        foregroundColor: const Color(0xFF594455),
        elevation: 0,
      ),

      // Background gradasi yang sama dengan halaman lainnya
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
                // Header halaman
                const Text(
                  'Informasi Produk',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF594455),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan informasi produk yang ingin ditambahkan.',
                  style: TextStyle(
                    color: Color(0xFF806B80),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 25),

                // Form dalam kartu putih
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD99AAF)
                            .withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama produk
                      _fieldLabel('Nama Produk'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          'Masukkan nama produk',
                          Icons.shopping_bag_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Harga produk
                      _fieldLabel('Harga Produk (Rp)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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

                      // Stok produk
                      _fieldLabel('Jumlah Stok'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
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

                      // Kategori produk
                      _fieldLabel('Kategori Produk'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          'Pilih kategori',
                          Icons.category_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Kategori 1',
                            child: Text('Kategori 1'),
                          ),
                          DropdownMenuItem(
                            value: 'Kategori 2',
                            child: Text('Kategori 2'),
                          ),
                          DropdownMenuItem(
                            value: 'Kategori 3',
                            child: Text('Kategori 3'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      // Tombol simpan
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: saveProduct,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text(
                            'Simpan Produk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFD99AAF),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tombol batal
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color(0xFFB76E8B),
                            side: const BorderSide(
                              color: Color(0xFFD99AAF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
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

  // Label untuk setiap input
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

  // Desain input dengan tema pink dan lavender
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
