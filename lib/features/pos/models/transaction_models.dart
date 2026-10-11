import '../../inventory/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

class TransactionModel {
  final String id;
  final List<CartItemModel> items;
  final double totalAmount;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
  });
}
