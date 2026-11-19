import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_app/app/constants/product_categories.dart';
import 'package:kasir_app/features/auth/models/user_model.dart';
import 'package:kasir_app/features/pos/controllers/pos_controller.dart';
import 'package:kasir_app/shared/utils/currency_formatter.dart';

void main() {
  test('CurrencyFormatter menambahkan pemisah ribuan', () {
    expect(CurrencyFormatter.formatRupiah(0), 'Rp 0');
    expect(CurrencyFormatter.formatRupiah(1500), 'Rp 1.500');
    expect(CurrencyFormatter.formatRupiah(1500000), 'Rp 1.500.000');
  });

  test('UserModel.fromMap memakai nilai default dan uid autentikasi', () {
    final user = UserModel.fromMap({'name': 'Ani'}, 'uid-1');

    expect(user.id, 'uid-1');
    expect(user.name, 'Ani');
    expect(user.username, '');
    expect(user.role, 'kasir');
  });

  group('ProductCategories', () {
    test('daftar standar dipakai untuk produk baru', () {
      expect(ProductCategories.withExisting(null), ProductCategories.all);
      expect(ProductCategories.withExisting('  '), ProductCategories.all);
      expect(ProductCategories.withExisting('Minuman'), ProductCategories.all);
    });

    test('kategori lama di luar daftar tetap bisa dipilih', () {
      expect(
        ProductCategories.withExisting('Umum'),
        [...ProductCategories.all, 'Umum'],
      );
    });

    test('kategori lama dirapikan dari spasi', () {
      expect(
        ProductCategories.withExisting('  Elektronik '),
        [...ProductCategories.all, 'Elektronik'],
      );
    });
  });

  group('PosController.computeDiscountAmount', () {
    double nominal(double subtotal, double input) {
      return PosController.computeDiscountAmount(
        subtotal: subtotal,
        mode: DiscountMode.nominal,
        input: input,
      );
    }

    double percent(double subtotal, double input) {
      return PosController.computeDiscountAmount(
        subtotal: subtotal,
        mode: DiscountMode.percentage,
        input: input,
      );
    }

    test('nominal dipakai apa adanya', () {
      expect(nominal(20000, 5000), 5000);
    });

    test('nominal dibatasi subtotal', () {
      expect(nominal(20000, 25000), 20000);
    });

    test('persentase dihitung dari subtotal', () {
      expect(percent(20000, 10), 2000);
      expect(percent(20000, 100), 20000);
    });

    test('persentase di luar 0..100 tetap aman', () {
      expect(percent(20000, 0), 0);
      expect(percent(20000, 150), 20000);
      expect(percent(20000, -10), 0);
    });

    test('subtotal nol atau negatif menghasilkan diskon nol', () {
      expect(nominal(0, 5000), 0);
      expect(percent(-100, 50), 0);
    });

    test('pembulatan tidak boleh melebihi subtotal', () {
      // Subtotal pecahan: 0.6 dibulatkan ke 1.0 akan melebihi subtotal.
      expect(nominal(0.6, 0.6), 0.6);
      expect(percent(0.6, 100), 0.6);
    });

    test('diskon dibulatkan ke rupiah utuh', () {
      expect(nominal(20000, 4999.4), 4999);
      expect(nominal(20000, 4999.6), 5000);
    });
  });
}
