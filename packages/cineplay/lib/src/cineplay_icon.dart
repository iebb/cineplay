import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'cineplay_theme.dart';

/// One glyph from Cineplay's rounded icon set, colored by [CineplayTheme].
///
/// A [CineplayThemeData.glyphBuilder] can replace any glyph app-wide.
class CineplayIcon extends StatelessWidget {
  const CineplayIcon(
    this.glyph, {
    super.key,
    this.size = 20,
    this.color,
    this.shadow,
    this.semanticLabel,
  });

  final CineplayGlyph glyph;
  final double size;

  /// Defaults to the theme's chrome foreground color.
  final Color? color;

  /// Optional drop shadow, used when the icon sits directly on video.
  final Shadow? shadow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CineplayTheme.of(context);
    final resolved = color ?? theme.chrome.foregroundColor;
    final custom = theme.glyphBuilder?.call(
      context,
      glyph,
      resolved,
      size,
      shadow,
    );
    final icon =
        custom ??
        CustomPaint(
          size: Size.square(size),
          painter: CineplayGlyphPainter(glyph, resolved, shadow: shadow),
        );
    final sized = SizedBox.square(dimension: size, child: icon);
    if (semanticLabel == null) return sized;
    return Semantics(label: semanticLabel, image: true, child: sized);
  }
}

/// Paints one [CineplayGlyph] into a square canvas.
///
/// Solid glyphs (transport, speaker) are filled shapes with rounded corners;
/// line glyphs use a stroke of 8.5% of the canvas width with round caps and
/// joins. Shapes are optically centered rather than bounding-box centered.
class CineplayGlyphPainter extends CustomPainter {
  const CineplayGlyphPainter(this.glyph, this.color, {this.shadow});

  final CineplayGlyph glyph;
  final Color color;
  final Shadow? shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = this.shadow;
    if (shadow != null && shadow.color.a > 0) {
      final paint = _basePaint(size, shadow.color);
      if (shadow.blurRadius > 0) {
        paint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          shadow.blurRadius * 0.5,
        );
      }
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      _paintGlyph(canvas, size, paint);
      canvas.restore();
    }
    _paintGlyph(canvas, size, _basePaint(size, color));
  }

  Paint _basePaint(Size size, Color color) => Paint()
    ..isAntiAlias = true
    ..color = color
    ..strokeWidth = math.max(1.6, size.width * 0.085)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _paintGlyph(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(w * x, h * y);
    final fill = Paint()
      ..isAntiAlias = true
      ..color = paint.color
      ..maskFilter = paint.maskFilter
      ..style = PaintingStyle.fill;
    final stroke = paint..style = PaintingStyle.stroke;

    switch (glyph) {
      case CineplayGlyph.play:
        canvas.drawPath(
          roundedPolygon([
            p(0.31, 0.17),
            p(0.85, 0.5),
            p(0.31, 0.83),
          ], w * 0.12),
          fill,
        );
      case CineplayGlyph.pause:
        for (final left in const [0.25, 0.59]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * left, h * 0.18, w * 0.16, h * 0.64),
              Radius.circular(w * 0.07),
            ),
            fill,
          );
        }
      case CineplayGlyph.previous:
      case CineplayGlyph.next:
        final mirror = glyph == CineplayGlyph.next;
        Offset q(double x, double y) => p(mirror ? 1 - x : x, y);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(q(0.17, 0.2), q(0.29, 0.8)),
            Radius.circular(w * 0.06),
          ),
          fill,
        );
        canvas.drawPath(
          roundedPolygon([q(0.83, 0.19), q(0.35, 0.5), q(0.83, 0.81)], w * 0.1),
          fill,
        );
      case CineplayGlyph.volume:
      case CineplayGlyph.muted:
        canvas.drawPath(
          roundedPolygon([
            p(0.1, 0.37),
            p(0.28, 0.37),
            p(0.5, 0.17),
            p(0.5, 0.83),
            p(0.28, 0.63),
            p(0.1, 0.63),
          ], w * 0.07),
          fill,
        );
        if (glyph == CineplayGlyph.volume) {
          for (final radius in const [0.15, 0.3]) {
            canvas.drawArc(
              Rect.fromCircle(center: p(0.5, 0.5), radius: w * radius),
              -math.pi * 0.27,
              math.pi * 0.54,
              false,
              stroke,
            );
          }
        } else {
          canvas.drawLine(p(0.66, 0.38), p(0.88, 0.62), stroke);
          canvas.drawLine(p(0.88, 0.38), p(0.66, 0.62), stroke);
        }
      case CineplayGlyph.pictureInPicture:
      case CineplayGlyph.exitPictureInPicture:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(w * 0.1, h * 0.2, w * 0.9, h * 0.8),
            Radius.circular(w * 0.13),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(w * 0.5, h * 0.49, w * 0.77, h * 0.67),
            Radius.circular(w * 0.05),
          ),
          fill,
        );
        if (glyph == CineplayGlyph.exitPictureInPicture) {
          canvas.drawPath(
            Path()
              ..moveTo(w * 0.41, h * 0.45)
              ..lineTo(w * 0.27, h * 0.34)
              ..moveTo(w * 0.26, h * 0.43)
              ..lineTo(w * 0.27, h * 0.34)
              ..lineTo(w * 0.36, h * 0.33),
            stroke,
          );
        }
      case CineplayGlyph.fullscreen:
      case CineplayGlyph.exitFullscreen:
        const inset = 0.17;
        const reach = 0.25;
        final radius = w * 0.08;
        final inward = glyph == CineplayGlyph.exitFullscreen;
        final path = Path();
        for (final (sx, sy) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
          double x(double t) => sx == 0 ? t : 1 - t;
          double y(double t) => sy == 0 ? t : 1 - t;
          // Outward corners hug the frame; inward corners point at it.
          final cornerT = inward ? inset + reach : inset;
          final tipT = inward ? inset : inset + reach;
          _roundedCorner(
            path,
            p(x(cornerT), y(tipT)),
            p(x(cornerT), y(cornerT)),
            p(x(tipT), y(cornerT)),
            radius,
          );
        }
        canvas.drawPath(path, stroke);
      case CineplayGlyph.close:
        canvas.drawLine(p(0.25, 0.25), p(0.75, 0.75), stroke);
        canvas.drawLine(p(0.75, 0.25), p(0.25, 0.75), stroke);
      case CineplayGlyph.more:
        for (final x in const [0.22, 0.5, 0.78]) {
          canvas.drawCircle(p(x, 0.5), w * 0.085, fill);
        }
      case CineplayGlyph.hideControls:
        // A closed eye: lid curve with three lashes.
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.12, h * 0.42)
            ..quadraticBezierTo(w * 0.5, h * 0.8, w * 0.88, h * 0.42),
          stroke,
        );
        canvas.drawLine(p(0.5, 0.61), p(0.5, 0.76), stroke);
        canvas.drawLine(p(0.3, 0.56), p(0.22, 0.69), stroke);
        canvas.drawLine(p(0.7, 0.56), p(0.78, 0.69), stroke);
      case CineplayGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.2, h * 0.52)
            ..lineTo(w * 0.41, h * 0.72)
            ..lineTo(w * 0.8, h * 0.3),
          stroke,
        );
    }
  }

  /// Draws an open two-segment polyline whose bend is a circular arc.
  static void _roundedCorner(
    Path path,
    Offset start,
    Offset corner,
    Offset end,
    double radius,
  ) {
    final toStart = start - corner;
    final toEnd = end - corner;
    final r = math.min(radius, math.min(toStart.distance, toEnd.distance));
    final a = corner + toStart / toStart.distance * r;
    final b = corner + toEnd / toEnd.distance * r;
    path
      ..moveTo(start.dx, start.dy)
      ..lineTo(a.dx, a.dy)
      ..conicTo(corner.dx, corner.dy, b.dx, b.dy, math.sqrt1_2)
      ..lineTo(end.dx, end.dy);
  }

  /// A closed polygon whose every vertex is replaced by a circular arc of
  /// [radius], tangent to both adjacent edges.
  static Path roundedPolygon(List<Offset> points, double radius) {
    final n = points.length;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final prev = points[(i - 1 + n) % n];
      final vertex = points[i];
      final next = points[(i + 1) % n];
      final toPrev = prev - vertex;
      final toNext = next - vertex;
      final lenPrev = toPrev.distance;
      final lenNext = toNext.distance;
      final cos =
          (toPrev.dx * toNext.dx + toPrev.dy * toNext.dy) / (lenPrev * lenNext);
      final angle = math.acos(cos.clamp(-1.0, 1.0));
      // Distance from the vertex to each tangent point, capped so arcs on
      // neighbouring vertices never overlap.
      final tangent = math.min(
        radius / math.tan(angle / 2),
        math.min(lenPrev, lenNext) * 0.45,
      );
      final a = vertex + toPrev / lenPrev * tangent;
      final b = vertex + toNext / lenNext * tangent;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.conicTo(vertex.dx, vertex.dy, b.dx, b.dy, math.sin(angle / 2));
    }
    return path..close();
  }

  @override
  bool shouldRepaint(CineplayGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.shadow != shadow;
}
