import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    final updatedAt = map['updatedAt'];

    return ProductModel(
      id: id,
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Umum',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
