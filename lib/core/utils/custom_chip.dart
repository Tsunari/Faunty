import 'package:flutter/material.dart';

class CustomContainerChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? outlineColor;
  final double outlineWidth;

  const CustomContainerChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 9,
    this.fontWeight = FontWeight.w600,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.outlineColor,
    this.outlineWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.onSurface.withAlpha(20),
        borderRadius: BorderRadius.circular(borderRadius),
        border: outlineColor != null
            ? Border.all(color: outlineColor!, width: outlineWidth)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor ?? Theme.of(context).colorScheme.primary.withAlpha(Colors.green.alpha),
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class CustomChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? outlineColor;
  final double outlineWidth;

  const CustomChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w500,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    this.outlineColor,
    this.outlineWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: fontWeight,
        ),
      ),
      padding: padding,
      visualDensity: VisualDensity.compact,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: outlineColor != null
            ? BorderSide(color: outlineColor!, width: outlineWidth)
            : BorderSide.none,
      ),
      // labelStyle is deprecated, use TextStyle in label instead
    );
  }
}