import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanScreen extends StatelessWidget {
  final void Function(String barcode) onScanned;

  const BarcodeScanScreen({Key? key, required this.onScanned})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first.rawValue;
          if (barcode != null && barcode.isNotEmpty) {
            onScanned(barcode);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
