import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Full-screen camera scanner for the restaurant-generated pickup QR.
/// Pops with the decoded plaintext token as soon as one is read — the
/// caller is responsible for submitting it to
/// `RiderOrdersRepository.scanPickupQr`, this screen never calls the API
/// itself so its own failure states stay purely about the camera/scan.
class PickupQrScannerScreen extends StatefulWidget {
  const PickupQrScannerScreen({super.key});

  @override
  State<PickupQrScannerScreen> createState() => _PickupQrScannerScreenState();
}

class _PickupQrScannerScreenState extends State<PickupQrScannerScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Get.back(result: value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan pickup QR'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.zap),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Point the camera at the QR code shown on the restaurant\'s screen.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.surface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
