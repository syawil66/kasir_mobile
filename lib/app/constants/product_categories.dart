/// Kategori produk standar yang dipakai form inventaris.
///
/// Kategori lain yang sudah tersimpan di Firestore (data lama) tetap
/// ditampilkan saat mengedit produk lewat [withExisting].
class ProductCategories {
  const ProductCategories._();

  static const List<String> all = [
    'Sembako',
    'Minuman',
    'Snack',
    'Lainnya',
  ];

  /// Label filter "tanpa kategori" di halaman kasir.
  static const String filterAll = 'Semua';

  /// Daftar kategori standar ditambah kategori produk yang sedang diedit
  /// jika belum termasuk daftar standar.
  static List<String> withExisting(String? existing) {
    final category = existing?.trim() ?? '';
    if (category.isEmpty || all.contains(category)) return all;
    return [...all, category];
  }
}
