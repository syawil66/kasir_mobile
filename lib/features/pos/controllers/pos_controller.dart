import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../inventory/models/product_model.dart';
import '../models/transaction_models.dart';

enum DiscountMode {
  nominal,
  percentage,
}

class PosController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<CartItemModel> cartItems = [];

  DiscountMode discountMode = DiscountMode.nominal;
  double _discountInput = 0;
  String? _checkoutId;

  /// Nota yang baru saja berhasil disimpan, dipakai untuk menampilkan struk.
  TransactionModel? lastCheckout;

  double get discountInput => _discountInput;

  // Hitung total sebelum diskon
  double get subtotal {
    return cartItems.fold(0, (total, item) => total + item.totalPrice);
  }

  // Nominal diskon efektif dalam Rupiah (selalu dibatasi 0 .. subtotal)
  double get discountAmount {
    return computeDiscountAmount(
      subtotal: subtotal,
      mode: discountMode,
      input: _discountInput,
    );
  }

  /// Perhitungan diskon dipisah agar bisa diuji tanpa Firebase.
  static double computeDiscountAmount({
    required double subtotal,
    required DiscountMode mode,
    required double input,
  }) {
    if (subtotal <= 0) return 0;
    final rawDiscount = mode == DiscountMode.nominal
        ? input
        : subtotal * (input / 100);
    final clamped = rawDiscount.clamp(0.0, subtotal).toDouble();
    // Bulatkan dulu, baru batasi lagi: harga lama yang masih pecahan bisa
    // membuat hasil pembulatan melebihi subtotal.
    final rounded = clamped.roundToDouble();
    return rounded > subtotal ? subtotal : rounded;
  }

  // Hitung total akhir setelah dikurangi diskon (minimal 0)
  double get finalTotal {
    return (subtotal - discountAmount).clamp(0.0, subtotal).toDouble();
  }

  void _resetCheckoutId() {
    _checkoutId = null;
  }

  void _syncNominalCap() {
    if (discountMode == DiscountMode.nominal && _discountInput > subtotal) {
      _discountInput = subtotal;
    }
  }

  /// Set diskon berdasarkan nominal Rupiah
  void setDiscountNominal(double nominal) {
    discountMode = DiscountMode.nominal;
    final clean = nominal.isFinite && nominal > 0 ? nominal : 0.0;
    _discountInput = clean > subtotal ? subtotal : clean;
    _resetCheckoutId();
  }

  /// Set diskon berdasarkan persentase (0 - 100%)
  void setDiscountPercentage(double percentage) {
    discountMode = DiscountMode.percentage;
    _discountInput = percentage.isFinite
        ? percentage.clamp(0.0, 100.0).toDouble()
        : 0.0;
    _resetCheckoutId();
  }

  /// Hapus diskon dan kembalikan ke mode nominal
  void clearDiscount() {
    discountMode = DiscountMode.nominal;
    _discountInput = 0;
    _resetCheckoutId();
  }

/// Tambah barang ke keranjang dengan validasi harga dan sisa stok
  String? addToCart(ProductModel product) {
    if (!product.price.isFinite || product.price <= 0) {
      return 'Harga ${product.name} tidak valid!';
    }

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

    _syncNominalCap();
    _resetCheckoutId();
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

    if (cartItems.isEmpty) {
      clearDiscount();
    } else {
      _syncNominalCap();
    }

    _resetCheckoutId();
    return null;
  }

  void clearCart() {
    cartItems.clear();
    clearDiscount();
  }

  /// Proses Checkout Tunai: Validasi Stok & Harga Terbaru + Simpan Transaksi
  /// menggunakan Firestore Transaction & Idempotency Key.
  Future<String?> processCheckout({
    required double cashPaid,
  }) async {
    if (cartItems.isEmpty) {
      return 'Keranjang belanja masih kosong!';
    }

    if (!cashPaid.isFinite || cashPaid < 0) {
      return 'Nominal pembayaran tidak valid!';
    }

    if (cashPaid < finalTotal) {
      return 'Uang tunai kurang dari total tagihan!';
    }

    final currentUser = AuthController.currentUser;
    if (currentUser == null) {
      return 'Sesi login tidak valid. Silakan login ulang.';
    }

    lastCheckout = null;

    try {
      // Gunakan ID transaksi yang sama selama isi keranjang tidak berubah (idempotency)
      final checkoutId =
          _checkoutId ??= _firestore.collection('transactions').doc().id;
      final transactionRef =
          _firestore.collection('transactions').doc(checkoutId);

      await _firestore.runTransaction((transaction) async {
        // 0. Cek idempotency: jika percobaan sebelumnya sudah commit di server, hentikan
        final existingTx = await transaction.get(transactionRef);
        if (existingTx.exists) {
          final existing = existingTx.data() ?? const <String, dynamic>{};
          final sameCashier = existing['cashierId'] == currentUser.id;
          final sameTotal =
              ((existing['finalTotal'] as num?)?.toDouble() ?? -1) == finalTotal;

          if (!sameCashier || !sameTotal) {
            throw Exception(
              'ID transaksi ini sudah dipakai untuk transaksi lain. '
              'Tutup lalu buka ulang halaman kasir sebelum mencoba lagi.',
            );
          }

          return;
        }

        // 1. Baca seluruh dokumen produk terlebih dahulu (wajib sebelum operasi tulis)
        final Map<DocumentReference, int> updatedStocks = {};

        for (final item in cartItems) {
          final productRef =
              _firestore.collection('products').doc(item.product.id);
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw Exception('Produk ${item.product.name} tidak ditemukan.');
          }

          final data = snapshot.data()!;
          final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
          final currentPrice = (data['price'] as num?)?.toDouble();

          if (currentPrice == null || !currentPrice.isFinite) {
            throw Exception('Harga produk ${item.product.name} tidak valid.');
          }

          if ((currentPrice - item.product.price).abs() > 0.01) {
            throw Exception(
              'Harga ${item.product.name} telah berubah menjadi '
              'Rp ${currentPrice.toStringAsFixed(0)}. '
              'Hapus dan tambahkan ulang item ke keranjang.',
            );
          }

          if (currentStock < item.quantity) {
            throw Exception(
              'Stok ${item.product.name} tidak mencukupi (sisa: $currentStock).',
            );
          }

          updatedStocks[productRef] = currentStock - item.quantity;
        }

        // 2. Kurangi stok masing-masing produk di Firestore.
        //    `lastCheckoutId` mengikat pengurangan stok ke transaksi yang dibuat
        //    pada commit yang sama; firestore.rules memvalidasi kecocokannya.
        updatedStocks.forEach((productRef, newStock) {
          transaction.update(productRef, {
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
            'lastCheckoutId': checkoutId,
          });
        });

        // 3. Simpan riwayat nota transaksi
        final computedSubtotal = subtotal;
        final computedDiscount = discountAmount;
        final computedFinalTotal = finalTotal;

        transaction.set(transactionRef, {
          'items': cartItems.map((e) => e.toMap()).toList(),
          // Delta stok per produk, dipakai firestore.rules untuk memverifikasi
          // bahwa pengurangan stok cocok dengan isi transaksi.
          'stockDeltas': {
            for (final item in cartItems) item.product.id: item.quantity,
          },
          'subtotal': computedSubtotal,
          'discount': computedDiscount,
          'discountMode': discountMode.name,
          'discountInput': _discountInput,
          'finalTotal': computedFinalTotal,
          'cashPaid': cashPaid,
          'changeAmount': cashPaid - computedFinalTotal,
          'paymentMethod': 'Tunai',
          'cashierId': currentUser.id,
          'cashierName': currentUser.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Simpan salinan nota untuk ditampilkan sebagai struk sebelum
      // keranjang dikosongkan.
      lastCheckout = TransactionModel(
        id: checkoutId,
        items: cartItems
            .map(
              (item) => CartItemModel(
                product: item.product,
                quantity: item.quantity,
              ),
            )
            .toList(),
        subtotal: subtotal,
        discount: discountAmount,
        discountMode: discountMode.name,
        discountInput: _discountInput,
        finalTotal: finalTotal,
        cashPaid: cashPaid,
        changeAmount: cashPaid - finalTotal,
        paymentMethod: 'Tunai',
        cashierId: currentUser.id,
        cashierName: currentUser.name,
        createdAt: DateTime.now(),
      );

      clearCart();
      return null; // Checkout sukses
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}