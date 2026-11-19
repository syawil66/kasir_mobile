import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../controllers/pos_controller.dart';
import '../../models/cart_item_model.dart';
import 'payment_dialog.dart';

/// Panel keranjang belanja: ubah jumlah, atur diskon (Nominal/Persentase),
/// lalu lanjut ke pembayaran Tunai.
class CartBottomSheet extends StatefulWidget {
  final PosController controller;
  final VoidCallback? onChanged;

  const CartBottomSheet({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);
  static const Color dangerMauve = Color(0xFFC45D78);

  late final TextEditingController _discountController;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initialVal = widget.controller.discountInput;
    _discountController = TextEditingController(
      text: initialVal > 0 ? initialVal.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call();
  }

  void _syncDiscountField() {
    final effectiveInput = widget.controller.discountInput;
    final formatted =
        effectiveInput > 0 ? effectiveInput.toStringAsFixed(0) : '';

    if (_discountController.text != formatted) {
      _discountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _updateQuantity(String productId, int newQuantity) {
    final error = widget.controller.updateQuantity(productId, newQuantity);

    setState(() {
      _error = error;
      if (error == null) {
        _syncDiscountField();
        _notifyChanged();
      }
    });
  }

  void _switchDiscountMode(DiscountMode mode) {
    if (widget.controller.discountMode == mode) return;

    setState(() {
      _error = null;
      if (mode == DiscountMode.nominal) {
        widget.controller.setDiscountNominal(0);
      } else {
        widget.controller.setDiscountPercentage(0);
      }
      _discountController.clear();
      _notifyChanged();
    });
  }

  void _applyDiscount(String rawValue) {
    final parsed = double.tryParse(rawValue.trim()) ?? 0;

    setState(() {
      _error = null;
      if (widget.controller.discountMode == DiscountMode.nominal) {
        widget.controller.setDiscountNominal(parsed);
      } else {
        widget.controller.setDiscountPercentage(parsed);
      }
      if (rawValue.trim().isNotEmpty) {
        _syncDiscountField();
      }
      _notifyChanged();
    });
  }

  void _clearDiscount() {
    setState(() {
      _error = null;
      widget.controller.clearDiscount();
      _discountController.clear();
      _notifyChanged();
    });
  }

  Future<void> _checkout() async {
    if (_isProcessing || widget.controller.cartItems.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentDialog(
        total: widget.controller.finalTotal,
        onConfirm: (cashPaid) {
          return widget.controller.processCheckout(
            cashPaid: cashPaid,
          );
        },
      ),
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    // Hanya bersihkan input diskon jika checkout benar-benar berhasil
    if (success == true) {
      _discountController.clear();
      _notifyChanged();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxHeight = (mediaQuery.size.height - bottomInset) * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEADCE8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Detail Keranjang',
                        style: TextStyle(
                          fontSize: 20,
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
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: dangerMauve,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _buildItems(),
                const SizedBox(height: 12),
                _buildDiscountSection(),
                const SizedBox(height: 12),
                _buildTotals(),
                const SizedBox(height: 16),
                _buildCheckoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItems() {
    final items = widget.controller.cartItems;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_shopping_cart_outlined,
                size: 44,
                color: Color(0xFFD0B7C9),
              ),
              SizedBox(height: 10),
              Text(
                'Keranjang masih kosong',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkMauve,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pilih produk di halaman kasir untuk memulai transaksi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedMauve,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            const Divider(
              height: 20,
              color: Color(0xFFF0E5EC),
            ),
          _buildItemRow(items[index]),
        ],
      ],
    );
  }

  Widget _buildItemRow(CartItemModel item) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: darkMauve,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${CurrencyFormatter.formatRupiah(item.product.price)} '
                '• sisa stok ${item.product.stock}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFAA96A8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _quantityControl(item),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(
            CurrencyFormatter.formatRupiah(item.totalPrice),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFFB76E8B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quantityControl(CartItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9EAF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove,
            onTap: () => _updateQuantity(
              item.product.id,
              item.quantity - 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: darkMauve,
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add,
            onTap: () => _updateQuantity(
              item.product.id,
              item.quantity + 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: darkMauve),
      ),
    );
  }

  Widget _buildDiscountSection() {
    final isPercentage =
        widget.controller.discountMode == DiscountMode.percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Jenis Diskon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedMauve,
                ),
              ),
            ),
            _buildModeChip(
              label: 'Nominal (Rp)',
              isSelected: !isPercentage,
              onTap: () => _switchDiscountMode(DiscountMode.nominal),
            ),
            const SizedBox(width: 8),
            _buildModeChip(
              label: 'Persen (%)',
              isSelected: isPercentage,
              onTap: () => _switchDiscountMode(DiscountMode.percentage),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _applyDiscount,
          decoration: InputDecoration(
            labelText: isPercentage ? 'Diskon (%)' : 'Diskon (Rp)',
            hintText: isPercentage ? '0 - 100' : '0',
            labelStyle: const TextStyle(
              color: mutedMauve,
              fontSize: 13,
            ),
            hintStyle: const TextStyle(
              color: Color(0xFFB4A6B5),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.local_offer_outlined,
              color: accentPink,
              size: 20,
            ),
            suffixText: isPercentage ? '%' : null,
            suffixStyle: const TextStyle(
              color: darkMauve,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: widget.controller.discountInput > 0
                ? IconButton(
                    tooltip: 'Hapus diskon',
                    onPressed: _clearDiscount,
                    icon: const Icon(
                      Icons.close,
                      color: accentPink,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFFFF9FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFF0DCE8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFF0DCE8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: accentPink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentPink : const Color(0xFFF9EAF0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentPink : const Color(0xFFF0DCE8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : mutedMauve,
          ),
        ),
      ),
    );
  }

  Widget _buildTotals() {
    final controller = widget.controller;
    final isPercentage = controller.discountMode == DiscountMode.percentage;
    final discountLabel = isPercentage && controller.discountInput > 0
        ? 'Diskon (${controller.discountInput.toStringAsFixed(0)}%)'
        : 'Diskon';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: Column(
        children: [
          _totalRow(
            'Subtotal',
            CurrencyFormatter.formatRupiah(controller.subtotal),
          ),
          if (controller.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _totalRow(
              discountLabel,
              '- ${CurrencyFormatter.formatRupiah(controller.discountAmount)}',
              valueColor: dangerMauve,
            ),
          ],
          const Divider(height: 16, color: Color(0xFFEADCE8)),
          _totalRow(
            'Total Pembayaran',
            CurrencyFormatter.formatRupiah(controller.finalTotal),
            isBold: true,
            valueColor: darkMauve,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? darkMauve : mutedMauve,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 17 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? mutedMauve,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    final isEmpty = widget.controller.cartItems.isEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isEmpty || _isProcessing ? null : _checkout,
        icon: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.payment_rounded),
        label: Text(
          isEmpty ? 'Keranjang Kosong' : 'Lanjut ke Pembayaran',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentPink.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}