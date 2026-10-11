class CurrencyFormatter {
  static String formatRupiah(num number) {
    String str = number.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3}(?=(\d{3})+(?!\d)))');
    String result = str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return 'Rp $result';
  }
}