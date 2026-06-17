// lib/widgets/wave_background_painter.dart — Anggota 2
// Custom Drawing: Latar belakang gelombang (wave) menggunakan CustomPainter
import 'package:flutter/material.dart';

/// CustomPainter yang menggambar multi-layer wave (ombak) sebagai dekorasi latar.
/// Menggunakan Path + cubicTo untuk membuat kurva halus.
class WaveBackgroundPainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;
  final double wavePhase;

  WaveBackgroundPainter({
    required this.baseColor,
    required this.accentColor,
    this.wavePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWaveLayer(
      canvas,
      size,
      color: accentColor.withOpacity(0.08),
      yOffset: size.height * 0.55,
      amplitude: size.height * 0.12,
      phase: wavePhase,
    );

    _drawWaveLayer(
      canvas,
      size,
      color: baseColor.withOpacity(0.12),
      yOffset: size.height * 0.65,
      amplitude: size.height * 0.10,
      phase: wavePhase + 0.5,
    );

    _drawWaveLayer(
      canvas,
      size,
      color: Colors.white.withOpacity(0.07),
      yOffset: size.height * 0.75,
      amplitude: size.height * 0.08,
      phase: wavePhase + 1.0,
    );
  }

  void _drawWaveLayer(
    Canvas canvas,
    Size size, {
    required Color color,
    required double yOffset,
    required double amplitude,
    required double phase,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, yOffset);

    // Menggunakan cubicTo untuk membuat gelombang yang smooth
    final waveWidth = size.width;

    // Titik kontrol pertama (naik)
    path.cubicTo(
      waveWidth * (0.2 + phase * 0.05),
      yOffset - amplitude,
      waveWidth * (0.35 + phase * 0.03),
      yOffset + amplitude * 0.6,
      waveWidth * 0.5,
      yOffset,
    );

    // Titik kontrol kedua (turun)
    path.cubicTo(
      waveWidth * (0.65 - phase * 0.03),
      yOffset - amplitude * 0.6,
      waveWidth * (0.8 - phase * 0.05),
      yOffset + amplitude,
      waveWidth,
      yOffset,
    );

    // Tutup path ke bawah
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveBackgroundPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.wavePhase != wavePhase;
}

/// Widget wrapper yang menggabungkan gradient background + wave overlay.
/// Siap pakai langsung di FlexibleSpaceBar atau Container header.
class WaveBackground extends StatelessWidget {
  final Color primaryColor;
  final Color gradientEndColor;
  final Widget? child;
  final double wavePhase;

  const WaveBackground({
    super.key,
    required this.primaryColor,
    required this.gradientEndColor,
    this.child,
    this.wavePhase = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, gradientEndColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: WaveBackgroundPainter(
          baseColor: primaryColor,
          accentColor: gradientEndColor,
          wavePhase: wavePhase,
        ),
        child: child,
      ),
    );
  }
}
