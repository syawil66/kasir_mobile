import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_app/features/pos/controllers/pos_controller.dart';
import 'package:kasir_app/features/pos/controllers/transaction_controller.dart';

void main() {
  group('CheckoutKey', () {
    late int counter;
    late CheckoutKey key;

    String nextId() => 'tx-${++counter}';

    setUp(() {
      counter = 0;
      key = CheckoutKey(nextId);
    });

    test('ID dipakai ulang selama keranjang tidak berubah', () {
      final first = key.id;
      expect(key.id, first);
      expect(key.id, first);
      expect(counter, 1);
    });

    test('ID berganti setelah isi keranjang berubah', () {
      final first = key.id;
      key.onContentChanged();
      final second = key.id;

      expect(second, isNot(first));
      expect(counter, 2);
    });

    test('percobaan ulang tanpa mengubah keranjang memakai ID yang sama', () {
      final id = key.id;

      // Retry karena jaringan gagal, keranjang tidak disentuh.
      expect(key.id, id);
      expect(counter, 1);
    });

    test(
      'setelah gagal ambigu, ID tidak berganti walau keranjang diubah',
      () {
        final first = key.id;
        key.markUnresolved();

        // Kasir menambah/mengubah item setelah melihat pesan error.
        key.onContentChanged();
        key.onContentChanged();

        expect(key.id, first);
        expect(key.isUnresolved, isTrue);
        expect(counter, 1);
      },
    );

    test('reset setelah percobaan pasti memakai ID baru', () {
      final first = key.id;
      key.markUnresolved();
      key.onContentChanged();
      expect(key.id, first);

      key.reset();
      expect(key.isUnresolved, isFalse);

      final second = key.id;
      expect(second, isNot(first));
      expect(counter, 2);
    });

    test('gagal validasi tidak menandai percobaan sebagai ambigu', () {
      final id = key.id;
      expect(key.isUnresolved, isFalse);

      // Validasi gagal sebelum menulis: ID boleh diganti setelah keranjang
      // diperbaiki.
      key.onContentChanged();
      expect(key.id, isNot(id));
    });
  });

  group('VoidResult', () {
    test('sukses tanpa produk terlewat', () {
      const result = VoidResult.success();

      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.skippedProducts, isEmpty);
    });

    test('sukses dengan produk yang sudah dihapus', () {
      const result = VoidResult.success(skippedProducts: ['Kopi']);

      expect(result.isSuccess, isTrue);
      expect(result.skippedProducts, ['Kopi']);
    });

    test('gagal membawa pesan error', () {
      const result = VoidResult.failure('Hanya admin yang dapat membatalkan.');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Hanya admin yang dapat membatalkan.');
      expect(result.skippedProducts, isEmpty);
    });
  });
}
