import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerPopup extends StatefulWidget {
  final Function(String) onScan;

  const QRCodeScannerPopup({super.key, required this.onScan});

  static void show(BuildContext context, {required Function(String) onScan}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(2),
      builder: (BuildContext context) {
        return QRCodeScannerPopup(onScan: onScan);
      },
    );
  }

  @override
  State<QRCodeScannerPopup> createState() => _QRCodeScannerPopupState();
}

class _QRCodeScannerPopupState extends State<QRCodeScannerPopup> {
  static const neonGreen = Color(0xFF00FF85);
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(color: neonGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 450,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "SCAN TICKET",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Align the QR code within the frame.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        if (_hasScanned) return;

                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            setState(() => _hasScanned = true);
                            widget.onScan(barcode.rawValue!);
                            Navigator.pop(context);
                            break;
                          }
                        }
                      },
                    ),
                    // Optional target overlay
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: neonGreen, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on, color: neonGreen),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: neonGreen),
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
