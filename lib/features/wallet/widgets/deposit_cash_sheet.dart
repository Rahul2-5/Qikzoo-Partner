import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/payment_failure_message.dart';
import '../../../providers/wallet/wallet_provider.dart';
import '../../../repositories/wallet/wallet_repository.dart';

class DepositCashSheet extends ConsumerStatefulWidget {
  const DepositCashSheet({
    super.key,
    required this.currentCashInHand,
    this.onDepositSuccess,
  });

  final double currentCashInHand;
  final VoidCallback? onDepositSuccess;

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
  ConsumerState<DepositCashSheet> createState() => _DepositCashSheetState();
}

class _DepositCashSheetState extends ConsumerState<DepositCashSheet> {
  late final TextEditingController _amountController;
  CashDepositModel? _deposit;
  Timer? _poller;
  bool _loading = false;
  bool _successReported = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentCashInHand.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _createDeposit() async {
    final rupees = double.tryParse(_amountController.text.trim()) ?? 0;
    final amountPaise = (rupees * 100).round();
    final maxPaise = (widget.currentCashInHand * 100).round();
    if (amountPaise <= 0 || amountPaise > maxPaise) {
      setState(() {
        _error = 'Enter an amount up to your COD cash in hand.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deposit = await ref
          .read(walletRepositoryProvider)
          .createCashDeposit(amountPaise);
      if (!mounted) return;
      setState(() => _deposit = deposit);
      _startPolling();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = paymentFailureMessage(error.toString()) ??
              'Payment QR could not be generated. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
    unawaited(_checkStatus());
  }

  Future<void> _checkStatus() async {
    final current = _deposit;
    if (current == null || current.isTerminal) return;
    try {
      final latest =
          await ref.read(walletRepositoryProvider).getCashDeposit(current.id);
      if (!mounted) return;
      setState(() => _deposit = latest);
      if (latest.isTerminal) _poller?.cancel();
      if (latest.isPaid && !_successReported) {
        _successReported = true;
        ref.invalidate(walletProvider);
        ref.invalidate(transactionsProvider);
        widget.onDepositSuccess?.call();
      }
    } catch (_) {
      // Keep the last confirmed status and let the next poll retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    final deposit = _deposit;
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Deposit COD Cash',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            Text(
              'Cash held for Qikzoo: ${CurrencyFormatter.rupeesPrecise(widget.currentCashInHand)}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Delivery earnings are not included here. Deposits only reduce physical COD cash recorded from completed cash orders.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            if (deposit == null) ...[
              TextField(
                controller: _amountController,
                enabled: !_loading && widget.currentCashInHand > 0,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Amount to deposit',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final amount in [
                    500.0,
                    1000.0,
                    widget.currentCashInHand
                  ])
                    if (amount > 0 && amount <= widget.currentCashInHand)
                      ActionChip(
                        label: Text(
                          amount == widget.currentCashInHand
                              ? 'Full amount'
                              : CurrencyFormatter.rupeesPrecise(amount),
                        ),
                        onPressed: () =>
                            _amountController.text = amount.toStringAsFixed(2),
                      ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading || widget.currentCashInHand <= 0
                      ? null
                      : _createDeposit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.qrCode),
                  label: const Text('Generate payment QR'),
                ),
              ),
            ] else ...[
              _DepositQrState(deposit: deposit, onCheck: _checkStatus),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepositQrState extends StatelessWidget {
  const _DepositQrState({required this.deposit, required this.onCheck});

  final CashDepositModel deposit;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final paid = deposit.isPaid;
    return Column(
      children: [
        Text(
          CurrencyFormatter.rupeesPrecise(deposit.amountPaise / 100),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (!paid && deposit.qrPayload.startsWith('upi://pay?'))
          Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: QrImageView(data: deposit.qrPayload),
          )
        else
          Icon(
            paid ? LucideIcons.badgeCheck : LucideIcons.alertCircle,
            size: 64,
            color: paid ? const Color(0xFF0D8538) : Colors.orange,
          ),
        const SizedBox(height: 12),
        Text(
          paid
              ? 'Deposit verified. COD cash in hand is updated.'
              : deposit.status == 'PENDING'
                  ? 'Scan with any UPI banking app. Payment status and the exact amount are verified automatically.'
                  : deposit.failureReason ??
                      'This deposit could not be completed.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (!paid)
          OutlinedButton.icon(
            onPressed: onCheck,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Check payment status'),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
      ],
    );
  }
}
