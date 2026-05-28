import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Couche carte affichant la position GPS de l'utilisateur.
///
/// Compose deux layers flutter_map superposees :
/// - [CircleLayer] — cercle de precision bleu translucide (rayon = accuracy)
/// - [MarkerLayer] — point bleu plein avec pulsation
///
/// Si [position] est null, retourne un [SizedBox.shrink] (rien affiche).
/// Concu pour etre insere directement dans les children de [FlutterMap].
class UserPositionLayer extends StatelessWidget {
  const UserPositionLayer({
    super.key,
    required this.position,
    this.accuracy,
  });

  /// Position GPS courante. Null = pas de position disponible.
  final LatLng? position;

  /// Precision en metres. Determine le rayon du cercle translucide.
  /// Si null ou <= 0, le cercle de precision n'est pas affiche.
  final double? accuracy;

  /// Couleur du marqueur position utilisateur.
  static const Color _userBlue = Color(0xFF1976D2);

  /// Taille du marqueur en pixels.
  static const double _markerSize = 60.0;

  /// Taille du point bleu central en pixels.
  static const double _dotSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final pos = position;
    if (pos == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Cercle de precision GPS (bleu translucide)
        if (accuracy != null && accuracy! > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: pos,
                radius: accuracy!,
                useRadiusInMeter: true,
                color: _userBlue.withAlpha(30),
                borderColor: _userBlue.withAlpha(60),
                borderStrokeWidth: 1.0,
              ),
            ],
          ),

        // Point bleu plein avec pulsation
        MarkerLayer(
          markers: [
            Marker(
              point: pos,
              width: _markerSize,
              height: _markerSize,
              child: const _PulsingDot(
                size: _dotSize,
                color: _userBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Point bleu avec animation de pulsation.
///
/// Halo qui grandit et s'estompe en boucle autour du point central.
/// Utilise [AnimationController] avec [SingleTickerProviderStateMixin]
/// pour une animation fluide sans rebuild inutile.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo pulsant
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withAlpha(
                      (_opacityAnimation.value * 255).round(),
                    ),
                  ),
                ),
              );
            },
          ),

          // Cercle principal bleu avec bordure blanche
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(
                color: Colors.white,
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(64),
                  blurRadius: 4.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
