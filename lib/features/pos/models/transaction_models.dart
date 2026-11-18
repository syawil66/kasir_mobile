import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';
export 'cart_item_model.dart';

class TransactionModel {
  final String id;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double finalTotal;
  final double cashPaid;
  final double changeAmount;
  final String paymentMethod; // Default: 'Tunai' (tanpa QR)
  final String cashierId;
  final String cashierName;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.finalTotal,
    required this.cashPaid,
    required this.changeAmount,
    this.paymentMethod = 'Tunai',
    required this.cashierId,
    required this.cashierName,
    required this.createdAt,
  });

  double get totalAmount => finalTotal;
  DateTime get date => createdAt;

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      items: List<CartItemModel>.from(map['items'] ?? []),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      finalTotal: (map['finalTotal'] ?? 0).toDouble(),
      cashPaid: (map['cashPaid'] ?? 0).toDouble(),
      changeAmount: (map['changeAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'Tunai',
      cashierId: map['cashierId'] ?? '',
      cashierName: map['cashierName'] ?? 'Kasir',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'subtotal': subtotal,
      'discount': discount,
      'finalTotal': finalTotal,
      'cashPaid': cashPaid,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}