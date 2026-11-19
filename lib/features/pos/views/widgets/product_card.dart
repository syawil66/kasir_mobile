import 'package:flutter/material.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../inventory/models/product_model.dart';

/// Kartu produk pada halaman kasir. Menampilkan stok terkini dan tombol
/// tambah ke keranjang.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onAdd;

  const ProductCard({
    super.key,
    required this.product,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 5;

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isOutOfStock ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3DCE8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 38,
                    color: isOutOfStock
                        ? const Color(0xFFB9A7B5)
                        : const Color(0xFFD99AAF),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF594455),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product.category.isEmpty ? 'Tanpa kategori' : product.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFAA96A8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.formatRupiah(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFB76E8B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOutOfStock
                              ? 'Stok habis'
                              : 'Stok ${product.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOutOfStock
                                ? const Color(0xFFC45D78)
                                : isLowStock
                                    ? const Color(0xFFC48A3D)
                                    : const Color(0xFF8063A0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? const Color(0xFFE7DEE4)
                          : const Color(0xFFD99AAF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOutOfStock ? Icons.block : Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
