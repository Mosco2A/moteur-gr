import 'package:flutter/material.dart';

/// Variante de rendu du motif de profil altimetrique de marque (SW-SKIN-L6).
///
/// Le profil altimetrique est la seule signature graphique deja presente dans
/// l'app (fiche etape). On l'eleve au rang de MOTIF DE MARQUE reutilisable, en
/// trois traitements selon l'emploi (CCO §1.3 / peaux L8-L9) :
///  - [hero]      : aire remplie d'un `LinearGradient` de l'accent (defaut
///    `colorScheme.primary` -> transparent) + ligne de crete + graduations.
///    Emploi : heros de la fiche etape, splash. Identite assumee (le degrade
///    d'accent est une NOUVELLE identite vs l'ancien remplissage plat — arbitre
///    par Christophe/Skynet, cf. mandat L6).
///  - [watermark] : trace tres discret / faible opacite, sans graduations —
///    fond de vignette (catalogue peau-aware, cablage HORS perimetre L6).
///  - [outline]   : ligne de crete seule (ni remplissage ni graduations) —
///    ornement sobre.
enum BrandAltiVariant { hero, watermark, outline }

/// Motif de profil altimetrique de marque, reutilisable (SW-SKIN-L6).
///
/// Factorise la logique de trace du profil altimetrique jusqu'ici inline dans
/// la fiche etape (`trek_stage_detail_screen.dart`, `_ElevationProfilePainter`)
/// vers un composant partage, et l'enrichit d'un degrade d'accent (variante
/// [hero]). Teinte par l'accent-sentier (defaut `colorScheme.primary`), il est
/// reutilisable en fiche etape (heros), catalogue (watermark de vignette) et
/// splash (ornement).
///
/// ## Deux sources de trace
/// La fiche etape ne dispose PAS d'une liste de points d'altitude reelle : le
/// modele `Stage` ne porte que des scalaires (D+, D-, distance). Le trace
/// actuel est donc SYNTHETIQUE (montee -> sommet -> descente derive de D+/D-).
/// Pour offrir l'API generique demandee (`elevations`) TOUT EN garantissant la
/// parite de trace sur la fiche etape, deux points d'entree coexistent :
///  - constructeur par defaut [BrandAltiMotif.new] : rend une liste de points
///    d'altitude REELS (usage general : GPX, watermark de vignette, splash) ;
///  - [BrandAltiMotif.synthetic] : reproduit EXACTEMENT la courbe synthetique
///    historique a partir de D+/D-/distance (parite fiche etape).
///
/// ## Robustesse (mandat L6)
/// Liste d'altitudes vide ou reduite a un seul point : AUCUN crash. Le painter
/// ne dessine rien (aire vide) ou une ligne plate — repli gracieux.
///
/// ## Exemple d'usage `watermark` (fond de vignette catalogue)
/// Le cablage catalogue lui-meme est hors perimetre (arbitrage #A2), mais le
/// motif s'emploie ainsi comme filigrane derriere une vignette :
/// ```dart
/// Stack(
///   fit: StackFit.expand,
///   children: [
///     // Filigrane discret derriere le contenu de la vignette.
///     BrandAltiMotif(
///       elevations: stage.elevationSamples, // liste de points reels
///       variant: BrandAltiVariant.watermark,
///       accent: trailAccent, // accent-sentier injecte
///     ),
///     Padding(
///       padding: EdgeInsets.all(12),
///       child: Text(stage.name),
///     ),
///   ],
/// )
/// ```
class BrandAltiMotif extends StatelessWidget {
  /// Motif a partir d'une liste de points d'altitude REELS (usage general).
  ///
  /// Les valeurs sont mises a l'echelle sur la hauteur disponible (min/max de
  /// la liste). Liste vide / 1 point => repli gracieux (rien / ligne plate).
  const BrandAltiMotif({
    super.key,
    required List<double> elevations,
    this.variant = BrandAltiVariant.hero,
    this.accent,
    this.height = _defaultHeight,
  })  : _elevations = elevations,
        _synthetic = null;

  /// Motif reproduisant la courbe SYNTHETIQUE historique de la fiche etape
  /// (montee -> sommet -> descente derive de D+/D-), pour la PARITE de trace.
  ///
  /// A employer quand seuls les scalaires D+/D-/distance sont disponibles
  /// (modele `Stage`). Rend le meme profil qu'avant L6, avec en plus le degrade
  /// d'accent en variante [hero] (identite assumee).
  BrandAltiMotif.synthetic({
    super.key,
    required int elevationGain,
    required int elevationLoss,
    required double distance,
    this.variant = BrandAltiVariant.hero,
    this.accent,
    this.height = _defaultHeight,
  })  : _elevations = const <double>[],
        _synthetic = AltiSyntheticProfile(
          elevationGain: elevationGain,
          elevationLoss: elevationLoss,
          distance: distance,
        );

  /// Hauteur par defaut du motif (iso l'encart historique de la fiche etape).
  static const double _defaultHeight = 160;

  /// Points d'altitude reels (vide pour le constructeur [BrandAltiMotif.synthetic]).
  final List<double> _elevations;

  /// Parametres de la courbe synthetique (non `null` seulement pour
  /// [BrandAltiMotif.synthetic]).
  final AltiSyntheticProfile? _synthetic;

  /// Traitement de rendu (heros rempli / watermark discret / ligne seule).
  final BrandAltiVariant variant;

  /// Couleur d'accent teintant le motif. `null` => `colorScheme.primary`
  /// (accent-sentier injecte par le theme). JAMAIS de couleur en dur.
  final Color? accent;

  /// Hauteur du motif. Defaut : [_defaultHeight].
  final double height;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: AltiProfilePainter(
          elevations: _elevations,
          synthetic: _synthetic,
          variant: variant,
          accent: effectiveAccent,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Parametres de la courbe SYNTHETIQUE historique (D+/D-/distance).
///
/// Type de valeur immuable decrivant le profil derive des scalaires d'une
/// etape (le modele `Stage` ne porte pas de points d'altitude reels). Sert la
/// parite de trace de la fiche etape et de cle d'egalite pour `shouldRepaint`.
/// Public car expose par le constructeur de [AltiProfilePainter].
@immutable
class AltiSyntheticProfile {
  const AltiSyntheticProfile({
    required this.elevationGain,
    required this.elevationLoss,
    required this.distance,
  });

  /// Denivele positif (m).
  final int elevationGain;

  /// Denivele negatif (m).
  final int elevationLoss;

  /// Distance de l'etape (km), pour la cote de droite.
  final double distance;

  @override
  bool operator ==(Object other) =>
      other is AltiSyntheticProfile &&
      other.elevationGain == elevationGain &&
      other.elevationLoss == elevationLoss &&
      other.distance == distance;

  @override
  int get hashCode => Object.hash(elevationGain, elevationLoss, distance);
}

/// Painter du motif de profil altimetrique de marque (SW-SKIN-L6).
///
/// Factorise `_ElevationProfilePainter` (ex-inline fiche etape) et generalise :
///  - source SYNTHETIQUE ([synthetic] non `null`) : trace historique exact
///    (montee -> sommet -> descente derive de D+/D-), avec cotes 0 km /
///    +D+ m / distance ;
///  - source POINTS REELS ([elevations]) : polyligne mise a l'echelle (min/max),
///    cotes distance a definir par l'appelant (graduations minimales ici).
///
/// Les trois [variant]s partagent la meme geometrie ; seules changent l'aire
/// (degrade d'accent en [hero], voile discret en [watermark], aucune en
/// [outline]) et les graduations (presentes en [hero] uniquement, comme avant).
class AltiProfilePainter extends CustomPainter {
  AltiProfilePainter({
    required this.elevations,
    required this.synthetic,
    required this.variant,
    required this.accent,
  });

  /// Points d'altitude reels (vide en mode synthetique).
  final List<double> elevations;

  /// Parametres synthetiques (non `null` => mode synthetique historique).
  final AltiSyntheticProfile? synthetic;

  /// Traitement de rendu.
  final BrandAltiVariant variant;

  /// Couleur d'accent (deja resolue, jamais `null`).
  final Color accent;

  /// Opacite de l'aire remplie selon la variante.
  double get _fillAlpha {
    switch (variant) {
      case BrandAltiVariant.hero:
        return 1; // degrade opaque->transparent gere par le shader
      case BrandAltiVariant.watermark:
        return 0.10; // filigrane tres discret
      case BrandAltiVariant.outline:
        return 0; // pas d'aire
    }
  }

  /// Opacite de la ligne de crete selon la variante.
  double get _strokeAlpha {
    switch (variant) {
      case BrandAltiVariant.hero:
        return 1;
      case BrandAltiVariant.watermark:
        return 0.25;
      case BrandAltiVariant.outline:
        return 1;
    }
  }

  /// Les graduations (cotes chiffrees) ne s'affichent qu'en [hero] (comme le
  /// trace historique) — un watermark/outline reste graphiquement muet.
  bool get _showLabels => variant == BrandAltiVariant.hero;

  static const double _padding = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Repli gracieux : mode points reels sans donnee exploitable (0 ou 1 point)
    // => rien a tracer (mandat L6 : pas de crash, pas de trace bidon).
    if (synthetic == null && elevations.length < 2) return;

    final path =
        synthetic != null ? _syntheticPath(size) : _elevationsPath(size);
    if (path == null) return;

    _paintFill(canvas, size, path);
    _paintStroke(canvas, path);
    if (_showLabels) _paintLabels(canvas, size);
  }

  /// Peint l'aire sous la courbe (degrade d'accent en [hero], voile discret en
  /// [watermark], rien en [outline]).
  void _paintFill(Canvas canvas, Size size, Path linePath) {
    if (_fillAlpha <= 0) return;

    final fillPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(size.width - _padding, size.height - _padding)
      ..lineTo(_padding, size.height - _padding)
      ..close();

    final Paint fillPaint;
    if (variant == BrandAltiVariant.hero) {
      // Degrade d'accent vertical : accent en haut -> transparent en bas.
      // NOUVELLE identite de marque (assumee) vs l'ancien aplat a alpha 30.
      fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.45),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill;
    } else {
      // Watermark : aplat tres discret.
      fillPaint = Paint()
        ..color = accent.withValues(alpha: _fillAlpha)
        ..style = PaintingStyle.fill;
    }

    canvas.drawPath(fillPath, fillPaint);
  }

  /// Peint la ligne de crete (opacite selon la variante).
  void _paintStroke(Canvas canvas, Path linePath) {
    final strokePaint = Paint()
      ..color = accent.withValues(alpha: _strokeAlpha)
      ..strokeWidth = variant == BrandAltiVariant.watermark ? 1.5 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);
  }

  /// Construit le trace SYNTHETIQUE historique (montee -> sommet -> descente).
  ///
  /// Reproduit a l'identique la geometrie de `_ElevationProfilePainter`
  /// (courbes de Bezier quadratiques, ratio du pic derive de D+/(D+ + D-)),
  /// pour la parite de trace de la fiche etape.
  Path _syntheticPath(Size size) {
    final s = synthetic!;
    final drawWidth = size.width - _padding * 2;
    final drawHeight = size.height - _padding * 2;

    final total = s.elevationGain + s.elevationLoss;
    final peakRatio = total > 0 ? s.elevationGain / total : 0.5;

    const startX = _padding;
    final startY = size.height - _padding;
    final peakX = _padding + drawWidth * peakRatio;
    const peakY = _padding;
    final endX = size.width - _padding;
    final endRatio =
        total > 0 ? (s.elevationGain - s.elevationLoss) / total : 0.0;
    final endY =
        size.height - _padding - drawHeight * endRatio.clamp(0.0, 0.8);

    return Path()
      ..moveTo(startX, startY)
      ..quadraticBezierTo(
        (startX + peakX) / 2,
        startY - drawHeight * 0.3,
        peakX,
        peakY,
      )
      ..quadraticBezierTo(
        (peakX + endX) / 2,
        peakY + drawHeight * 0.2,
        endX,
        endY,
      );
  }

  /// Construit le trace a partir de points d'altitude REELS, mis a l'echelle
  /// sur la hauteur disponible (min/max de la liste).
  ///
  /// Retourne `null` si les points ne sont pas exploitables (garde deja faite
  /// en amont, ceinture + bretelles). Un profil totalement plat (min == max)
  /// rend une ligne mediane (pas de division par zero).
  Path? _elevationsPath(Size size) {
    if (elevations.length < 2) return null;

    final drawWidth = size.width - _padding * 2;
    final drawHeight = size.height - _padding * 2;
    if (drawWidth <= 0 || drawHeight <= 0) return null;

    var minAlt = elevations.first;
    var maxAlt = elevations.first;
    for (final e in elevations) {
      if (e < minAlt) minAlt = e;
      if (e > maxAlt) maxAlt = e;
    }
    final range = maxAlt - minAlt;

    double xFor(int i) =>
        _padding + drawWidth * (i / (elevations.length - 1));
    double yFor(double alt) {
      // range 0 (profil plat) => ligne mediane, aucune division par zero.
      final norm = range == 0 ? 0.5 : (alt - minAlt) / range;
      return size.height - _padding - drawHeight * norm;
    }

    final path = Path()..moveTo(xFor(0), yFor(elevations.first));
    for (var i = 1; i < elevations.length; i++) {
      path.lineTo(xFor(i), yFor(elevations[i]));
    }
    return path;
  }

  /// Peint les cotes chiffrees (0 km / +D+ m au sommet / distance a droite).
  ///
  /// Uniquement en mode synthetique + variante [hero] (parite fiche etape). En
  /// mode points reels, on n'a pas la distance ici : l'appelant compose les
  /// legendes autour du motif si besoin (perimetre L6 : pas de sur-ingenierie).
  void _paintLabels(Canvas canvas, Size size) {
    final s = synthetic;
    if (s == null) return;

    final drawWidth = size.width - _padding * 2;
    final total = s.elevationGain + s.elevationLoss;
    final peakRatio = total > 0 ? s.elevationGain / total : 0.5;
    final peakX = _padding + drawWidth * peakRatio;
    final startY = size.height - _padding;

    final textStyle = TextStyle(
      color: accent,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    TextPainter tp(String text) => TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

    final startLabel = tp('0 km');
    startLabel.paint(canvas, Offset(_padding, startY + 2));

    final endLabel = tp('${s.distance.toStringAsFixed(1)} km');
    endLabel.paint(
      canvas,
      Offset(size.width - _padding - endLabel.width, startY + 2),
    );

    final peakLabel = tp('+${s.elevationGain} m');
    peakLabel.paint(
      canvas,
      Offset(peakX - peakLabel.width / 2, _padding - 14),
    );
  }

  @override
  bool shouldRepaint(covariant AltiProfilePainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.accent != accent ||
        oldDelegate.synthetic != synthetic ||
        !_sameElevations(oldDelegate.elevations, elevations);
  }

  static bool _sameElevations(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
