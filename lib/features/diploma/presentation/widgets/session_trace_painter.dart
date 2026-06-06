import 'package:flutter/material.dart';

/// Peint le tracé GPS d'une session normalisé dans la zone disponible.
///
/// Finitions V8 F3 — rendu léger du récap diplôme : polyline du
/// parcours réel (offsets x=longitude, y=latitude), sans tuiles ni
/// réseau (offline-first). Départ et arrivée marqués par des points.
class SessionTracePainter extends CustomPainter {
  SessionTracePainter({
    required this.points,
    required this.color,
    this.strokeWidth = 3.0,
    this.padding = 12.0,
  });

  /// Points GPS bruts (dx = longitude, dy = latitude).
  final List<Offset> points;

  /// Couleur du tracé (couleur primaire du sentier).
  final Color color;

  /// Épaisseur du tracé.
  final double strokeWidth;

  /// Marge intérieure autour du tracé.
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Bounding box du tracé.
    var minX = points.first.dx, maxX = points.first.dx;
    var minY = points.first.dy, maxY = points.first.dy;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    // Echelle uniforme (aspect preserve), centree.
    final scale = (spanX == 0 && spanY == 0)
        ? 1.0
        : [
            if (spanX > 0) drawW / spanX,
            if (spanY > 0) drawH / spanY,
          ].reduce((a, b) => a < b ? a : b);
    final offsetX = padding + (drawW - spanX * scale) / 2;
    final offsetY = padding + (drawH - spanY * scale) / 2;

    // Latitude croissante = vers le haut -> inversion de l'axe y.
    Offset project(Offset p) => Offset(
          offsetX + (p.dx - minX) * scale,
          offsetY + (maxY - p.dy) * scale,
        );

    final path = Path()..moveTo(project(points.first).dx, project(points.first).dy);
    for (final p in points.skip(1)) {
      final proj = project(p);
      path.lineTo(proj.dx, proj.dy);
    }

    final tracePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, tracePaint);

    // Marqueurs depart (plein) et arrivee (anneau).
    final startPaint = Paint()..color = color;
    canvas.drawCircle(project(points.first), strokeWidth * 1.8, startPaint);
    final endPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(project(points.last), strokeWidth * 1.8, endPaint);
  }

  @override
  bool shouldRepaint(SessionTracePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
