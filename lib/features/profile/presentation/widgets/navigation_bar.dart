import 'dart:ui';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const NavBar({super.key, required this.selectedIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: NavigationBarTheme(
              data: theme.navigationBarTheme.copyWith(
                backgroundColor: Colors.transparent,
                indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final textStyle = theme.textTheme.labelSmall ?? const TextStyle();
                  final isSelected = states.contains(WidgetState.selected);
                  return textStyle.copyWith(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.65),
                    size: 24,
                  );
                }),
              ),
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: Colors.transparent,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_filled),
                    label: translation(context: context, 'Home'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.group_outlined),
                    selectedIcon: const Icon(Icons.group),
                    label: translation(context: context, 'Communication'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.track_changes_outlined),
                    selectedIcon: const Icon(Icons.track_changes),
                    label: translation(context: context, 'Tracking'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.list_alt_outlined),
                    selectedIcon: const Icon(Icons.list_alt),
                    label: translation(context: context, 'Lists'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.more_horiz_outlined),
                    selectedIcon: const Icon(Icons.more_horiz),
                    label: translation(context: context, 'More'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OffsettedFABLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation location;
  final double offsetY;
  const OffsettedFABLocation(this.location, this.offsetY);
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset standardOffset = location.getOffset(scaffoldGeometry);
    return Offset(standardOffset.dx, standardOffset.dy - offsetY);
  }
}