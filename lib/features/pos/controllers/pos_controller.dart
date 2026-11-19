import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../inventory/models/product_model.dart';
import '../models/cart_item_model.dart';

class PosController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<CartItemModel> cartItems = [];

  double discountAmount = 0; // Nominal diskon dalam Rupiah

  // Hitung total sebelum diskon
  double get subtotal {
    return cartItems.fold(0, (total, item) => total + item.totalPrice);
  }

  // Hitung total akhir setelah dikurangi diskon (minimal 0)
  double get finalTotal {
    final total = subtotal - discountAmount;
    return total < 0 ? 0 : total;
  }

  /// Set diskon berdasarkan nominal Rupiah
  void setDiscountNominal(double nominal) {
    if (nominal < 0) {
      discountAmount = 0;
    } else if (nominal > subtotal) {
      discountAmount = subtotal;
    } else {
      discountAmount = nominal;
    }
  }

  /// Set diskon berdasarkan persentase (0 - 100%)
  void setDiscountPercentage(double percentage) {
    final validPercent = percentage.clamp(0, 100);
    discountAmount = subtotal * (validPercent / 100);
  }

  /// Tambah barang ke keranjang dengan validasi sisa stok
  String? addToCart(ProductModel product) {
    if (product.stock <= 0) {
      return 'Stok ${product.name} sudah habis!';
    }

    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (cartItems[index].quantity + 1 > product.stock) {
        return 'Jumlah melebihi sisa stok (${product.stock})!';
      }
      cartItems[index].quantity++;
    } else {
      cartItems.add(CartItemModel(product: product, quantity: 1));
    }

    // Sesuaikan ulang diskon jika subtotal berubah
    if (discountAmount > subtotal) {
      discountAmount = subtotal;
    }
    return null;
  }

  /// Ubah jumlah qty item di keranjang
  String? updateQuantity(String productId, int newQty) {
    final index = cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) return null;

    if (newQty <= 0) {
      cartItems.removeAt(index);
    } else if (newQty > cartItems[index].product.stock) {
      return 'Maksimal stok tersedia: ${cartItems[index].product.stock}';
    } else {
      cartItems[index].quantity = newQty;
    }

    if (discountAmount > subtotal) {
      discountAmount = subtotal;
    }
    return null;
  }

  void clearCart() {
    cartItems.clear();
    discountAmount = 0;
  }

  /// Proses Checkout: Simpan Transaksi + Potong Stok Otomatis di Firestore.
  /// Dapat dipakai oleh admin maupun kasir selama sesi login masih aktif.
  Future<String?> processCheckout({
    required double cashPaid,
    String paymentMethod = 'Tunai',
  }) async {
    if (cartItems.isEmpty) {
      return 'Keranjang belanja masih kosong!';
    }

    if (cashPaid < finalTotal) {
      return 'Uang tunai kurang dari total tagihan!';
    }

    final currentUser = AuthController.currentUser;
    if (currentUser == null) {
      return 'Sesi login tidak valid. Silakan login ulang.';
    }

    try {
      final transactionRef = _firestore.collection('transactions').doc();

      await _firestore.runTransaction((transaction) async {
        // 1. Cek stok terbaru tiap produk di server sebelum dipotong
        final Map<DocumentReference, int> updatedStocks = {};

        for (final item in cartItems) {
          final productRef =
              _firestore.collection('products').doc(item.product.id);
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw Exception('Produk ${item.product.name} tidak ditemukan.');
          }

          final currentStock =
              (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
          if (currentStock < item.quantity) {
            throw Exception(
              'Stok ${item.product.name} tidak mencukupi (sisa: $currentStock).',
            );
          }

          updatedStocks[productRef] = currentStock - item.quantity;
        }

        // 2. Kurangi stok masing-masing produk di Firestore
        updatedStocks.forEach((productRef, newStock) {
          transaction.update(productRef, {
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });

        // 3. Simpan riwayat nota transaksi
        transaction.set(transactionRef, {
          'items': cartItems.map((e) => e.toMap()).toList(),
          'subtotal': subtotal,
          'discount': discountAmount,
          'finalTotal': finalTotal,
          'cashPaid': cashPaid,
          'changeAmount': cashPaid - finalTotal,
          'paymentMethod': paymentMethod,
          'cashierId': currentUser.id,
          'cashierName': currentUser.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      clearCart();
      return null; // Checkout sukses
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}