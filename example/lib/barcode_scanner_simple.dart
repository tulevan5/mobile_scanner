import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerSimple extends StatefulWidget {
  const BarcodeScannerSimple({super.key});

  @override
  State<BarcodeScannerSimple> createState() => _BarcodeScannerSimpleState();
}

class _BarcodeScannerSimpleState extends State<BarcodeScannerSimple> {
  Barcode? _barcode;
  MobileScannerController? _controller;

  @override
  void initState() {
    _controller = MobileScannerController();
    super.initState();
  }

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple scanner')),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (barcodes) {
                  if (mounted) {
                    _controller?.setAnalyzeImage(false);
                    setState(() {
                      _barcode = barcodes.barcodes.firstOrNull;
                    });
                    if (_barcode != null) {
                      Scaffold.of(context).showBottomSheet((builder) => Container(
                        height: 300,
                        color: Colors.red,
                        child: ElevatedButton(
                            onPressed: () {
                              _controller?.setAnalyzeImage(true);
                              Navigator.of(context).pop();
                            },
                            child: Text("Click next scan")),
                      ));
                    }
                  }
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: Center(child: _buildBarcode(_barcode))),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
