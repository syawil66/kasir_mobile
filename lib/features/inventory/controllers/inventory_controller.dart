import '../models/product_model.dart';

class InventoryController {
  // Data dummy untuk produk
  final List<ProductModel> products = [
    ProductModel(
      id: 'PRD001',
      name: 'Produk A',
      price: 10000,
      stock: 50,
      category: 'Kategori 1',
    ),
    ProductModel(
      id: 'PRD002',
      name: 'Produk B',
      price: 20000,
      stock: 30,
      category: 'Kategori 2',
    ),
    ProductModel(
      id: 'PRD003',
      name: 'Produk C',
      price: 15000,
      stock: 20,
      category: 'Kategori 1',
    ),
  ];
}