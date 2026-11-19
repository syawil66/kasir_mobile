import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';
export 'cart_item_model.dart';

class TransactionModel {
  final String id;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final String discountMode;
  final double discountInput;
  final double finalTotal;
  final double cashPaid;
  final double changeAmount;
  final String paymentMethod; // Tunai
  final String cashierId;
  final String cashierName;
  final DateTime createdAt;

  /// Nota yang dibatalkan admin. Stok sudah dikembalikan saat pembatalan.
  final bool voided;
  final DateTime? voidedAt;
  final String? voidedBy;

  TransactionModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    this.discountMode = 'nominal',
    this.discountInput = 0,
    required this.finalTotal,
    required this.cashPaid,
    required this.changeAmount,
    this.paymentMethod = 'Tunai',
    required this.cashierId,
    required this.cashierName,
    required this.createdAt,
    this.voided = false,
    this.voidedAt,
    this.voidedBy,
  });

  double get totalAmount => finalTotal;
  DateTime get date => createdAt;

  int get itemCount =>
      items.fold(0, (total, item) => total + item.quantity);

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'];
    final createdAt = map['createdAt'];

    return TransactionModel(
      id: id,
      items: rawItems is List
          ? rawItems
                .whereType()
                .map(
                  (item) => CartItemModel.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      discountMode: map['discountMode']?.toString() ?? 'nominal',
      discountInput: (map['discountInput'] as num?)?.toDouble() ?? 0,
      finalTotal: (map['finalTotal'] as num?)?.toDouble() ?? 0,
      cashPaid: (map['cashPaid'] as num?)?.toDouble() ?? 0,
      changeAmount: (map['changeAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod']?.toString() ?? 'Tunai',
      cashierId: map['cashierId']?.toString() ?? '',
      cashierName: map['cashierName']?.toString() ?? 'Kasir',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      voided: map['voided'] == true,
      voidedAt: map['voidedAt'] is Timestamp
          ? (map['voidedAt'] as Timestamp).toDate()
          : null,
      voidedBy: map['voidedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'discountMode': discountMode,
      'discountInput': discountInput,
      'finalTotal': finalTotal,
      'cashPaid': cashPaid,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'createdAt': FieldValue.serverTimestamp(),
      if (voided) ...{
        'voided': true,
        'voidedAt': FieldValue.serverTimestamp(),
        'voidedBy': voidedBy,
      },
    };
  }
}