/// Format tanggal/waktu Bahasa Indonesia tanpa dependency tambahan.
class DateFormatter {
  const DateFormatter._();

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Contoh: `19 November 2026`
  static String formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// Contoh: `19 November 2026, 14:05`
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)}, ${_two(date.hour)}:${_two(date.minute)}';
  }

  /// Contoh: `14:05`
  static String formatTime(DateTime date) {
    return '${_two(date.hour)}:${_two(date.minute)}';
  }

  /// Awal hari lokal (00:00) untuk filter rentang tanggal.
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
