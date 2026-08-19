import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/utils/currency_formatter.dart';

class DepositCashSheet extends StatefulWidget {
  final double currentCashInHand;
  final VoidCallback? onDepositSuccess;

  const DepositCashSheet({
    super.key,
    required this.currentCashInHand,
    this.onDepositSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required double currentCashInHand,
    VoidCallback? onDepositSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositCashSheet(
        currentCashInHand: currentCashInHand,
        onDepositSuccess: onDepositSuccess,
      ),
    );
  }

  @override
  State<DepositCashSheet> createState() => _DepositCashSheetState();
}

class _DepositCashSheetState extends State<DepositCashSheet> {
  late TextEditingController _amountController;
  int _selectedMethod = 0; // 0: UPI, 1: QR Code, 2: NetBanking
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.currentCashInHand > 0 ? widget.currentCashInHand : 500.0;
    _amountController = TextEditingController(text: defaultAmount.toInt().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    setState(() {
      _amountController.text = amount.toInt().toString();
    });
  }

  Future<void> _processDeposit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      Get.rawSnackbar(
        message: 'Please enter a valid amount',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop();

    // Show Success Dialog
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCheck, color: Color(0xFF0D8538), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deposit Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${amount.toStringAsFixed(0)} deposited to Qikzoo COD settlement.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your cash holding limit has been restored.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D8538),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D8538),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    widget.onDepositSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deposit Floating Cash',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Color(0xFF6B7280), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Current Cash in Hand: ${CurrencyFormatter.rupeesPrecise(widget.currentCashInHand)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
                labelText: 'Enter amount to deposit',
                labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D8538), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('₹500', 500),
                _buildQuickChip('₹1,000', 1000),
                _buildQuickChip('₹2,000', 2000),
                if (widget.currentCashInHand > 0)
                  _buildQuickChip('Full Amount', widget.currentCashInHand),
              ],
            ),
            const SizedBox(height: 18),

            // Payment Methods
            const Text(
              'Select Payment Option',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            _buildPaymentMethodTile(
              index: 0,
              icon: LucideIcons.smartphone,
              title: 'UPI Apps (GPay, PhonePe, Paytm)',
              subtitle: 'Instant auto-verification',
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodTile(
              index: 1,
              icon: LucideIcons.qrCode,
              title: 'Show Dynamic UPI QR Code',
              subtitle: 'Scan and pay from any banking app',
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodTile(
              index: 2,
              icon: LucideIcons.landmark,
              title: 'Net Banking / Debit Card',
              subtitle: 'Via secure banking gateway',
            ),
            const SizedBox(height: 20),

            // Proceed Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D8538),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Proceed to Deposit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double amount) {
    return InkWell(
      onTap: () => _setAmount(amount),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == index;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D8538) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF0D8538) : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF0D8538) : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Radio<int>(
              value: index,
              groupValue: _selectedMethod,
              activeColor: const Color(0xFF0D8538),
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
          ],
        ),
      ),
    );
  }
}
