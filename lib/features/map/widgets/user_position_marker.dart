import 'package:flutter/material.dart';

/// Marqueur bleu pulsant pour la position de l'utilisateur sur la carte.
///
/// Cercle bleu avec bordure blanche et ombre portée.
/// Animation de pulsation pour indiquer une position active.
class UserPositionMarker extends StatefulWidget {
  const UserPositionMarker({
    super.key,
    this.size = 20.0,
    this.color = const Color(0xFF1976D2),
  });

  /// Taille du cercle en pixels
  final double size;

  /// Couleur du marqueur (bleu par défaut)
  final Color color;

  @override
  State<UserPositionMarker> createState() => _UserPositionMarkerState();
}

class _UserPositionMarkerState extends State<UserPositionMarker>
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

          // Cercle principal
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
