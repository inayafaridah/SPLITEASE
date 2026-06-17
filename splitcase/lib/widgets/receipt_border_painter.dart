import 'package:flutter/material.dart';

class ReceiptBorderPainter extends CustomPainter {
  final Color color;
  final double zigZagWidth;
  final double zigZagHeight;
  final bool drawTop;
  final bool drawBottom;

  ReceiptBorderPainter({
    required this.color,
    this.zigZagWidth = 10.0,
    this.zigZagHeight = 6.0,
    this.drawTop = false,
    this.drawBottom = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    // Top border
    if (drawTop) {
      double x = 0;
      while (x < size.width) {
        x += zigZagWidth / 2;
        path.lineTo(x, zigZagHeight);
        x += zigZagWidth / 2;
        path.lineTo(x, 0);
      }
    } else {
      path.lineTo(size.width, 0);
    }

    path.lineTo(size.width, size.height);

    // Bottom border
    if (drawBottom) {
      double x = size.width;
      while (x > 0) {
        x -= zigZagWidth / 2;
        path.lineTo(x, size.height - zigZagHeight);
        x -= zigZagWidth / 2;
        path.lineTo(x, size.height);
      }
    } else {
      path.lineTo(0, size.height);
    }

    path.lineTo(0, 0);
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black, 4.0, false);
    
    // Draw background
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ReceiptBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.zigZagWidth != zigZagWidth ||
           oldDelegate.zigZagHeight != zigZagHeight ||
           oldDelegate.drawTop != drawTop ||
           oldDelegate.drawBottom != drawBottom;
  }
}

class ReceiptCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const ReceiptCard({
    super.key,
    required this.child,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ReceiptBorderPainter(color: color, drawBottom: true, drawTop: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: child,
      ),
    );
  }
}
