import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class InventoryController {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');

  /// Stream real-time daftar produk untuk halaman Inventaris & Kasir
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Tambah produk baru (Khusus Admin)
  Future<String?> addProduct({
    required String name,
    required String category,
    required double price,
    required int stock,
  }) async {
    try {
      await _productsRef.add({
        'name': name.trim(),
        'category': category.trim(),
        'price': price,
        'stock': stock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Gagal menambah produk: $e';
    }
  }

  /// Edit data atau stok produk (Khusus Admin)
  Future<String?> updateProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.id).update(product.toMap());
      return null;
    } catch (e) {
      return 'Gagal memperbarui produk: $e';
    }
  }

  /// Hapus produk (Khusus Admin)
  Future<String?> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
      return null;
    } catch (e) {
      return 'Gagal menghapus produk: $e';
    }
  }
}
