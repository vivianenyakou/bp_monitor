import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final url = barcode.rawValue;
    if (url == null) return;

    // Extraire le token depuis l'URL
    // Ex: https://app.g-autobp.tech/join?token=ABC123
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      _afficherErreur('QR code invalide.');
      return;
    }

    setState(() => _scanned = true);
    _controller.stop();

    // Naviguer vers l'inscription avec le token
    context.go('/register?qr_token=$token');
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(message),
        backgroundColor: AppColors.critique,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          'Scanner le QR code',
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        actions: [
          // Torche
          IconButton(
            icon:  const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [

          // Caméra
          MobileScanner(
            controller: _controller,
            onDetect:   _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlay(),
            child:   const SizedBox.expand(),
          ),

          // Instructions
          Positioned(
            bottom: 0,
            left:   0,
            right:  0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '📱',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pointez la caméra vers le QR code',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'de votre clinique ou hôpital',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Indicateur scan en cours
          if (_scanned)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'QR code détecté !',
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   18,
                        fontWeight: FontWeight.bold,
                      ),
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

// Overlay avec cadre de scan
class _ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.black54
      ..style       = PaintingStyle.fill;

    final scanSize = size.width * 0.7;
    final scanX    = (size.width - scanSize) / 2;
    final scanY    = (size.height - scanSize) / 2 - 40;

    // Fond sombre autour du cadre
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(scanX, scanY, scanSize, scanSize),
        const Radius.circular(16),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Cadre vert
    final borderPaint = Paint()
      ..color       = AppColors.primary
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(scanX, scanY, scanSize, scanSize),
        const Radius.circular(16),
      ),
      borderPaint,
    );

    // Coins colorés
    final cornerPaint = Paint()
      ..color       = AppColors.primary
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap   = StrokeCap.round;

    const cornerSize = 30.0;

    // Coin haut gauche
    canvas.drawLine(Offset(scanX, scanY + cornerSize), Offset(scanX, scanY), cornerPaint);
    canvas.drawLine(Offset(scanX, scanY), Offset(scanX + cornerSize, scanY), cornerPaint);

    // Coin haut droit
    canvas.drawLine(Offset(scanX + scanSize - cornerSize, scanY), Offset(scanX + scanSize, scanY), cornerPaint);
    canvas.drawLine(Offset(scanX + scanSize, scanY), Offset(scanX + scanSize, scanY + cornerSize), cornerPaint);

    // Coin bas gauche
    canvas.drawLine(Offset(scanX, scanY + scanSize - cornerSize), Offset(scanX, scanY + scanSize), cornerPaint);
    canvas.drawLine(Offset(scanX, scanY + scanSize), Offset(scanX + cornerSize, scanY + scanSize), cornerPaint);

    // Coin bas droit
    canvas.drawLine(Offset(scanX + scanSize - cornerSize, scanY + scanSize), Offset(scanX + scanSize, scanY + scanSize), cornerPaint);
    canvas.drawLine(Offset(scanX + scanSize, scanY + scanSize - cornerSize), Offset(scanX + scanSize, scanY + scanSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}