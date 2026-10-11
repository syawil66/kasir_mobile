import '../models/transaction_models.dart';
import '../../inventory/models/product_model.dart';

class PosController {
  final List<CartItemModel> cart = [];

  // Menambahkan item ke keranjang
  void addToCart(ProductModel product) {
    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      cart[index].quantity++;
    } else {
      cart.add(CartItemModel(product: product));
    }
  }

  // Menghitung total harga keranjang
  double get grandTotal {
    return cart.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void clearCart() {
    cart.clear();
  }
}