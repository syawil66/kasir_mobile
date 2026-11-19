import '../../inventory/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  /// Dipakai saat membaca item dari dokumen transaksi di Firestore.
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      product: ProductModel(
        id: map['productId']?.toString() ?? '',
        name: map['productName']?.toString() ?? '',
        price: (map['priceAtPurchase'] as num?)?.toDouble() ?? 0,
        stock: 0,
        category: '',
        updatedAt: null,
      ),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'priceAtPurchase': product.price,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}
