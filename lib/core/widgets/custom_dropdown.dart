import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? icon;
  final Color? dropdownColor;
  final TextStyle? style;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.borderColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.icon,
    this.dropdownColor,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? primaryColor.withOpacity(0.5)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButton<T>(
        value: value,
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(borderRadius),
        style: Theme.of(context).textTheme.bodyMedium,
        dropdownColor: Theme.of(context).colorScheme.surface,
        items: items,
        onChanged: onChanged,
        isExpanded: false,
      ),
    );
  }
}
