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
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Tag')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                // Simple overlay
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(24),
                  ),
                )
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(child: Text('Align the QR code within the frame')),
          )
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue ?? barcodes.first.displayValue;
    final code = value?.trim();
    if (code != null && code.isNotEmpty) {
      _handled = true;
      await controller.stop();
      if (!mounted) return;
      Navigator.of(context).pop(code);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
