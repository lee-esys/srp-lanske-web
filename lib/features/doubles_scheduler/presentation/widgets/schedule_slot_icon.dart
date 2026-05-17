import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleSlotIcon extends StatelessWidget {
  const ScheduleSlotIcon({
    super.key,
    required this.slotNumber,
    required this.displayName,
    this.playerId,
    this.size = 28,
  });

  final int slotNumber;
  final String displayName;
  final String? playerId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final seedText = [
      if (playerId != null && playerId!.isNotEmpty) playerId,
      displayName,
      slotNumber.toString(),
    ].join(':');

    final seed = _stableHash(seedText);
    final baseColor = _colorFromSeed(seed);
    final foregroundColor = _foregroundFor(baseColor);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarbleSlotIconPainter(
          seed: seed,
          baseColor: baseColor,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              slotNumber.toString(),
              style: GoogleFonts.pottaOne(
                color: foregroundColor,
                fontSize: size * 0.54,
                fontWeight: FontWeight.w400,
                height: 1,
                shadows: [
                  Shadow(
                    color: foregroundColor == Colors.white
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.45),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static int _stableHash(String value) {
    var hash = 2166136261;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xffffffff;
    }

    return hash;
  }

  static Color _colorFromSeed(int seed) {
    final hue = (seed % 360).toDouble();
    final saturation = 0.40 + ((seed >> 8) % 14) / 100;
    final lightness = 0.72 + ((seed >> 16) % 10) / 100;

    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

  static Color _foregroundFor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}

class _MarbleSlotIconPainter extends CustomPainter {
  const _MarbleSlotIconPainter({
    required this.seed,
    required this.baseColor,
  });

  static const int _blobCount = 9;
  static const double _blobBlurSigma = 2.2;
  static const double _blobAlpha = 0.34;

  final int seed;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.shortestSide / 2;

    final hsl = HSLColor.fromColor(baseColor);
    final colorA =
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor();
    final colorB = hsl
        .withHue((hsl.hue + 32) % 360)
        .withSaturation((hsl.saturation + 0.08).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.04).clamp(0.0, 1.0))
        .toColor();
    final colorC = hsl
        .withHue((hsl.hue + 76) % 360)
        .withSaturation((hsl.saturation - 0.04).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0))
        .toColor();

    final clipPath = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(clipPath);

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colorA, baseColor, colorB],
      ).createShader(rect);

    canvas.drawCircle(rect.center, radius, backgroundPaint);

    final random = math.Random(seed);
    for (var i = 0; i < _blobCount; i++) {
      final blobColor =
          [colorA, colorB, colorC][i % 3].withValues(alpha: _blobAlpha);
      final blobPaint = Paint()
        ..color = blobColor
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          _blobBlurSigma,
        );

      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final width = size.width * (0.28 + random.nextDouble() * 0.52);
      final height = size.height * (0.22 + random.nextDouble() * 0.46);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
        blobPaint,
      );
      canvas.restore();
    }

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(rect.center, radius - 0.5, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarbleSlotIconPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.baseColor != baseColor;
  }
}
