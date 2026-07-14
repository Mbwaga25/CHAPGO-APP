import 'package:flutter/material.dart';
import '../config/theme.dart';

class ChapgoLogo extends StatelessWidget {
  final bool showSubtitle;
  final double scale;

  const ChapgoLogo({
    super.key,
    this.showSubtitle = true,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow container wrapping the CustomPaint logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const CustomPaint(
              size: Size(120, 120),
              painter: ChapgoLogoPainter(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chapgo',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 8),
            Text(
              'Every rider deserves a verifiable\neconomic identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text(
              'Chapgo Company Limited',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChapgoLogoPainter extends CustomPainter {
  const ChapgoLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 512.0;
    final double scaleY = size.height / 512.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Draw Gold Gradient Circle
    const Rect rect = Rect.fromLTWH(0, 0, 512, 512);
    final Paint circlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(256, 256), 230, circlePaint);

    // 2. Draw white path
    canvas.save();
    canvas.translate(136, 136);
    canvas.scale(10);

    final Path path = Path();

    // First subpath
    path.moveTo(19.44, 9.03);
    path.lineTo(15.41, 5.0);
    path.lineTo(11.0, 5.0);
    path.lineTo(11.0, 7.0);
    path.lineTo(14.59, 7.0);
    path.relativeLineTo(2.0, 2.0);
    path.lineTo(5.0, 9.0);
    path.cubicTo(2.2, 9.0, 0.0, 11.2, 0.0, 14.0);
    path.lineTo(0.0, 19.0);
    path.lineTo(5.0, 19.0);
    path.cubicTo(5.0, 20.66, 6.34, 22.0, 8.0, 22.0);
    path.cubicTo(9.66, 22.0, 11.0, 20.66, 11.0, 19.0);
    path.lineTo(15.0, 19.0);
    path.cubicTo(15.0, 20.66, 16.34, 22.0, 18.0, 22.0);
    path.cubicTo(19.66, 22.0, 21.0, 20.66, 21.0, 19.0);
    path.lineTo(26.0, 19.0);
    path.lineTo(26.0, 14.0);
    path.cubicTo(26.0, 9.65, 22.47, 9.04, 20.44, 9.03);
    path.close();

    // Second subpath
    path.moveTo(8.0, 18.5);
    path.cubicTo(6.9, 18.5, 6.0, 17.6, 6.0, 16.5);
    path.cubicTo(6.0, 15.4, 6.9, 14.5, 8.0, 14.5);
    path.cubicTo(9.1, 14.5, 10.0, 15.4, 10.0, 16.5);
    path.cubicTo(10.0, 17.6, 9.1, 18.5, 8.0, 18.5);
    path.close();

    // Third subpath
    path.moveTo(11.12, 13.01);
    path.cubicTo(10.69, 13.31, 10.1, 13.5, 9.5, 13.5);
    path.cubicTo(7.85, 13.5, 6.5, 12.15, 6.5, 10.5);
    path.cubicTo(6.5, 8.85, 7.85, 7.5, 9.5, 7.5);
    path.cubicTo(10.03, 7.5, 10.52, 7.64, 10.95, 7.89);
    path.cubicTo(11.47, 8.18, 11.9, 8.63, 12.2, 9.16);
    path.lineTo(13.24, 8.12);
    path.cubicTo(12.58, 7.22, 11.61, 6.58, 10.5, 6.58);
    path.cubicTo(8.29, 6.58, 6.5, 8.37, 6.5, 10.58);
    path.cubicTo(6.5, 12.79, 8.29, 14.58, 10.5, 14.58);
    path.cubicTo(11.6, 14.58, 12.56, 14.14, 13.27, 13.42);
    path.lineTo(12.12, 12.01);
    path.close();

    // Fourth subpath
    path.moveTo(18.0, 18.5);
    path.cubicTo(16.9, 18.5, 16.0, 17.6, 16.0, 16.5);
    path.cubicTo(16.0, 15.4, 16.9, 14.5, 18.0, 14.5);
    path.cubicTo(19.1, 14.5, 20.0, 15.4, 20.0, 16.5);
    path.cubicTo(20.0, 17.6, 19.1, 18.5, 18.0, 18.5);
    path.close();

    // Fifth subpath
    path.moveTo(19.0, 13.0);
    path.lineTo(13.8, 13.0);
    path.lineTo(12.42, 11.5);
    path.lineTo(19.0, 11.5);
    path.lineTo(19.0, 13.0);
    path.close();

    final Paint pathPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, pathPaint);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
