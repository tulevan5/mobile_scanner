import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/overlay.dart';
import 'package:mobile_scanner_example/scanned_barcode_label.dart';

import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerWithScanWindow extends StatefulWidget {
  const BarcodeScannerWithScanWindow({super.key});

  @override
  State<BarcodeScannerWithScanWindow> createState() => _BarcodeScannerWithScanWindowState();
}

class _BarcodeScannerWithScanWindowState extends State<BarcodeScannerWithScanWindow> {
  final MobileScannerController controller = MobileScannerController(isAnalyze: true);

  final double borderWidth = 10;
  final Color overlayColor = const Color.fromRGBO(0, 0, 0, 82);
  final double borderRadius = 12;
  final double borderLength = 21;
  final double cutOutSize = 300;
  final double _cutOutBottomOffset = 110;
  final double scanWindowUpdateThreshold = 0.0;

  /// Error color (default: red)
  final Color errorColor = Colors.red;

  /// Show success or not (default: true)
  final bool showSuccess = true;

  /// Show error or not (default: true)
  final bool showError = true;

  /// Success color (default: green)
  final Color successColor = Colors.green;

  /// Overlay border color (default: white)
  final Color? borderColor = const Color(0xFF669900);

  Widget _buildBarcodeOverlay() {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized || !value.isRunning || value.error != null) {
          return const SizedBox();
        }

        return StreamBuilder<BarcodeCapture>(
          stream: controller.barcodes,
          builder: (context, snapshot) {
            final BarcodeCapture? barcodeCapture = snapshot.data;

            // No barcode.
            if (barcodeCapture == null || barcodeCapture.barcodes.isEmpty) {
              return const SizedBox();
            }

            final scannedBarcode = barcodeCapture.barcodes.first;

            // No barcode corners, or size, or no camera preview size.
            if (scannedBarcode.corners.isEmpty || value.size.isEmpty || barcodeCapture.size.isEmpty) {
              return const SizedBox();
            }

            return CustomPaint(
              painter: BarcodeOverlay(
                barcodeCorners: scannedBarcode.corners,
                barcodeSize: barcodeCapture.size,
                boxFit: BoxFit.contain,
                cameraPreviewSize: value.size,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScanWindow(Rect scanWindowRect) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized || !value.isRunning || value.error != null || value.size.isEmpty) {
          return const SizedBox();
        }

        return Container(
          decoration: ShapeDecoration(
            shape: OverlayShape(
              borderRadius: borderRadius,
              borderColor: borderColor ?? Colors.white,
              borderLength: borderLength,
              borderWidth: borderWidth,
              cutOutSize: cutOutSize,
              cutOutBottomOffset: _cutOutBottomOffset,
              overlayColor: overlayColor,
            ),
          ),
        );
        // return CustomPaint(
        //   painter: ScannerOverlay(scanWindow: scanWindowRect),
        // );
      },
    );
  }

  Widget _buildScanWindowDebug(Rect scanWindowRect) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized || !value.isRunning || value.error != null || value.size.isEmpty) {
          return const SizedBox();
        }
        return CustomPaint(
          painter: ScannerOverlay(scanWindow: scanWindowRect),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final borderOffset = borderWidth / 2;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final scanWindow = Rect.fromLTWH(
      width / 2 - cutOutSize / 2 + borderOffset,
      -_cutOutBottomOffset + height / 2 - cutOutSize / 2 + borderOffset,
      cutOutSize - borderWidth,
      cutOutSize - borderWidth,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: controller.switchCamera,
          ),
          IconButton(
            icon: controller.torchEnabled
                ? const Icon(Icons.flashlight_off_rounded)
                : const Icon(Icons.flashlight_on_rounded),
            onPressed: controller.toggleTorch,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Builder(builder: (context) {
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              fit: BoxFit.cover,
              onDetect: (barcodes) {
                if (mounted) {
                  // disable scan
                  controller.setAnalyzeImage(false);
                  controller.playBeepAndVibrate();
                  Scaffold.of(context).showBottomSheet((context) => Container(
                        height: 300,
                        color: Colors.amber,
                        child: ElevatedButton(
                          onPressed: () {
                            // enable scan
                            controller.setAnalyzeImage(true);
                            Navigator.of(context).pop();
                          },
                          child: Text("Click next scan"),
                        ),
                      ));
                }
              },
              // fit: BoxFit.contain,
              scanWindow: scanWindow,
              controller: controller,
              errorBuilder: (context, error, child) {
                return ScannerErrorWidget(error: error);
              },
            ),
            _buildScanWindow(scanWindow),
            // _buildScanWindowDebug(scanWindow),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 100,
                color: Colors.transparent,
                child: Column(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Scaffold.of(context).showBottomSheet(
                            (context) => Container(
                              height: 500,
                              width: MediaQuery.of(context).size.width,
                              color: Colors.amber,
                              child: Center(child: Text("Bottom sheet")),
                            ),
                          );
                        },
                        child: Text("Enter barcode")),
                    ScannedBarcodeLabel(barcodes: controller.barcodes),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

class ScannerOverlay extends CustomPainter {
  ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: use `Offset.zero & size` instead of Rect.largest
    // we need to pass the size to the custom paint widget
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BarcodeOverlay extends CustomPainter {
  BarcodeOverlay({
    required this.barcodeCorners,
    required this.barcodeSize,
    required this.boxFit,
    required this.cameraPreviewSize,
  });

  final List<Offset> barcodeCorners;
  final Size barcodeSize;
  final BoxFit boxFit;
  final Size cameraPreviewSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodeCorners.isEmpty || barcodeSize.isEmpty || cameraPreviewSize.isEmpty) {
      return;
    }

    final adjustedSize = applyBoxFit(boxFit, cameraPreviewSize, size);

    double verticalPadding = size.height - adjustedSize.destination.height;
    double horizontalPadding = size.width - adjustedSize.destination.width;
    if (verticalPadding > 0) {
      verticalPadding = verticalPadding / 2;
    } else {
      verticalPadding = 0;
    }

    if (horizontalPadding > 0) {
      horizontalPadding = horizontalPadding / 2;
    } else {
      horizontalPadding = 0;
    }

    final double ratioWidth;
    final double ratioHeight;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      ratioWidth = barcodeSize.width / adjustedSize.destination.width;
      ratioHeight = barcodeSize.height / adjustedSize.destination.height;
    } else {
      ratioWidth = cameraPreviewSize.width / adjustedSize.destination.width;
      ratioHeight = cameraPreviewSize.height / adjustedSize.destination.height;
    }

    final List<Offset> adjustedOffset = [
      for (final offset in barcodeCorners)
        Offset(
          offset.dx / ratioWidth + horizontalPadding,
          offset.dy / ratioHeight + verticalPadding,
        ),
    ];

    final cutoutPath = Path()..addPolygon(adjustedOffset, true);

    final backgroundPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    canvas.drawPath(cutoutPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
