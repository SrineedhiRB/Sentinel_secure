// lib/widgets/glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glass‑morphism container with optional gradient border.
///
/// Example usage:
/// ```dart
/// GlassContainer(
///   child: Text('Futuristic UI'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blur = 12.0,
    this.borderRadius,
    this.padding,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.08),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
