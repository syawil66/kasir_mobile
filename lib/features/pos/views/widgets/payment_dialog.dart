import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// Dialog pembayaran Tunai. Memvalidasi uang diterima serta memproses
/// checkout lewat [onConfirm].
class PaymentDialog extends StatefulWidget {
  final double total;
  final Future<String?> Function(double cashPaid) onConfirm;

  const PaymentDialog({
    super.key,
    required this.total,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);
  static const Color dangerMauve = Color(0xFFC45D78);

  final TextEditingController _cashController = TextEditingController();

  bool _isProcessing = false;
  String? _error;

  double? get _cashPaid {
    final raw = _cashController.text.trim();
    if (raw.isEmpty && widget.total == 0) return 0.0;
    return double.tryParse(raw);
  }

  double get _change {
    final paid = _cashPaid ?? 0;
    final change = paid - widget.total;
    return change < 0 ? 0 : change;
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _fillCash(double amount) {
    _cashController.text = amount.toStringAsFixed(0);
    setState(() {
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_isProcessing) return;

    final cashPaid = _cashPaid;
    if (cashPaid == null || cashPaid < 0 || (widget.total > 0 && cashPaid == 0)) {
      setState(() {
        _error = 'Masukkan nominal uang tunai yang diterima.';
      });
      return;
    }

    if (cashPaid < widget.total) {
      setState(() {
        _error = 'Uang yang diterima kurang dari total tagihan.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final error = await widget.onConfirm(cashPaid);

      if (!mounted) return;

      if (error != null) {
        setState(() {
          _isProcessing = false;
          _error = error;
        });
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _error = 'Terjadi kesalahan saat memproses pembayaran: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pembayaran Tunai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkMauve,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, color: mutedMauve),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Total Tagihan',
                style: TextStyle(color: mutedMauve, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatRupiah(widget.total),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkMauve,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _cashController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) {
                  setState(() {
                    _error = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Uang Tunai Diterima',
                  hintText: 'Contoh: 50000',
                  labelStyle: const TextStyle(
                    color: mutedMauve,
                    fontSize: 13,
                  ),
                  hintStyle: const TextStyle(
                    color: Color(0xFFB4A6B5),
                    fontSize: 13,
                  ),
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    color: darkMauve,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF9FC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFF0DCE8),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFF0DCE8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: accentPink,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmount('Uang Pas', widget.total),
                  if (widget.total < 50000)
                    _buildQuickAmount('Rp 50.000', 50000),
                  if (widget.total < 100000)
                    _buildQuickAmount('Rp 100.000', 100000),
                ],
              ),
              if (_cashPaid != null && _cashPaid! >= widget.total) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kembalian',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5F7A63),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(_change),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F7A63),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: dangerMauve,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _submit,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isProcessing ? 'Memproses...' : 'Selesaikan Transaksi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accentPink.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmount(String label, double amount) {
    return OutlinedButton(
      onPressed: _isProcessing ? null : () => _fillCash(amount),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB76E8B),
        side: const BorderSide(color: Color(0xFFEADCE8)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}