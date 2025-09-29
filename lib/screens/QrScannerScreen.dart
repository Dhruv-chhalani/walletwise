import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerScreen extends StatelessWidget {
  final Function(String) onPaymentCompleted;

  QrScannerScreen({required this.onPaymentCompleted});

  Future<void> _handleQRCode(String qrCode, BuildContext context) async {
    if (qrCode.startsWith("upi://pay")) {
      final uri = Uri.parse(qrCode);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        onPaymentCompleted("success");
      } else {
        onPaymentCompleted("failed");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Not a valid UPI QR Code")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan UPI QR")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final qrCode = barcode.rawValue ?? "";
            _handleQRCode(qrCode, context);
            break; // Stop after first scan
          }
        },
      ),
    );
  }
}
