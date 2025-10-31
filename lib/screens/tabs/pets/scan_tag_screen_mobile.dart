import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanTagScreenImpl extends StatefulWidget {
  const ScanTagScreenImpl({super.key});

  @override
  State<StatefulWidget> createState() => _ScanTagScreenImplState();
}

class _ScanTagScreenImplState extends State<ScanTagScreenImpl> {
  final MobileScannerController controller = MobileScannerController();
  bool _handled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start the scanner
    controller.start();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.stop();
    } else if (Platform.isIOS) {
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC1E8F7);
    const accentColor = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Tag'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
      ),
      body: Column(
        children: <Widget>[
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: primaryColor.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Align the QR code within the frame',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner view
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Camera Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                controller.start();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Scan frame overlay
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(40),
                  ),
                ),
                // Corner indicators
                IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.all(40),
                    child: Stack(
                      children: [
                        // Top-left corner
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.teal, width: 6),
                                left: BorderSide(color: Colors.teal, width: 6),
                              ),
                            ),
                          ),
                        ),
                        // Top-right corner
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.teal, width: 6),
                                right: BorderSide(color: Colors.teal, width: 6),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-left corner
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.teal,
                                  width: 6,
                                ),
                                left: BorderSide(color: Colors.teal, width: 6),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-right corner
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.teal,
                                  width: 6,
                                ),
                                right: BorderSide(color: Colors.teal, width: 6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Error message overlay
                if (_errorMessage != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom instructions
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Position QR code clearly in the frame',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.toggleTorch(),
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: const Text('Toggle Flash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    try {
      final barcodes = capture.barcodes;
      if (barcodes.isEmpty) return;

      final barcode = barcodes.first;
      final value = barcode.rawValue ?? barcode.displayValue;
      final code = value?.trim();

      if (code == null || code.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid QR code';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
        return;
      }

      // Mark as handled and stop scanner
      _handled = true;
      await controller.stop();

      if (!mounted) return;

      // Return the scanned code
      Navigator.of(context).pop(code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Scan error: ${e.toString()}';
          _handled = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
