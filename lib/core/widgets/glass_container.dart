import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 6.0,
    this.borderRadius = 16.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.boxShadow,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Harmonious translucent color palette tailored to monochrome theme brightness
    final defaultColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.85);

    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final containerColor = color ?? defaultColor;
    final containerBorderColor = borderColor ?? defaultBorderColor;

    return Container(
      margin: margin,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isDark ? Colors.black38 : Colors.black12,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: containerBorderColor,
                  width: borderWidth,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
