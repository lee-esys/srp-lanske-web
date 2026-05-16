import 'dart:math' as math;

import 'package:flutter/material.dart';

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
          child: Text(
            slotNumber.toString(),
            style: TextStyle(
              color: foregroundColor,
              fontSize: size * 0.48,
              fontWeight: FontWeight.w800,
              height: 1,
              shadows: [
                Shadow(
                  color: foregroundColor == Colors.white
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.55),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
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
    final saturation = 0.54 + ((seed >> 8) % 20) / 100;
    final lightness = 0.50 + ((seed >> 16) % 12) / 100;

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

  final int seed;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.shortestSide / 2;

    final hsl = HSLColor.fromColor(baseColor);
    final colorA =
        hsl.withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
    final colorB = hsl.withHue((hsl.hue + 34) % 360).toColor();
    final colorC =
        hsl.withHue((hsl.hue + 72) % 360).withSaturation(0.42).toColor();

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
    for (var i = 0; i < 5; i++) {
      final blobColor = [colorA, colorB, colorC][i % 3].withValues(alpha: 0.42);
      final blobPaint = Paint()
        ..color = blobColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final width = size.width * (0.42 + random.nextDouble() * 0.42);
      final height = size.height * (0.28 + random.nextDouble() * 0.42);

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
