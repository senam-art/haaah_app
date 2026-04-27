import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Animated pulsing badge that says "GREEN LIT" 
class GreenLightBadge extends StatefulWidget {
  const GreenLightBadge({super.key});

  @override
  State<GreenLightBadge> createState() => _GreenLightBadgeState();
}

class _GreenLightBadgeState extends State<GreenLightBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: HaaahTheme.neonGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HaaahTheme.neonGreen.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: HaaahTheme.neonGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Text(
          '🟢 GREEN LIT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: HaaahTheme.neonGreen,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Reusable animated widget wrapper using ListenableBuilder.
class AnimatedBuilder extends StatelessWidget {
  final Listenable listenable;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, child) => builder(context, child),
      child: child,
    );
  }
}
