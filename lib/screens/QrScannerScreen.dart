import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerScreen extends StatefulWidget {
  final int transactionId;

  QrScannerScreen({required this.transactionId});

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _hasScanned = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (_hasScanned) return; // Prevent multiple scans
    
    setState(() {
      _hasScanned = true;
    });

    // Check if it's a valid UPI QR code
    if (qrCode.startsWith("upi://pay") || qrCode.contains("upi://")) {
      try {
        final uri = Uri.parse(qrCode);
        
        // Try to launch the UPI URL
        bool launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          // Payment app opened successfully
          // Return to previous screen and indicate payment app was launched
          Navigator.pop(context, 'launched');
        } else {
          // Could not open payment app
          _showError("Could not open payment app");
        }
      } catch (e) {
        _showError("Invalid QR code: $e");
      }
    } else {
      _showError("Not a valid UPI QR Code");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    
    // Allow scanning again after error
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hasScanned = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan UPI QR Code"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_hasScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final qrCode = barcode.rawValue ?? "";
                if (qrCode.isNotEmpty) {
                  _handleQRCode(qrCode);
                  break;
                }
              }
            },
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions at bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Position QR code within the frame',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
