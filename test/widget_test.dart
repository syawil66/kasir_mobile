import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_app/features/auth/models/user_model.dart';
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
}
