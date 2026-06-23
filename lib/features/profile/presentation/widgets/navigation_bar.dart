import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const NavBar({super.key, required this.selectedIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: Theme.of(context).navigationBarTheme.copyWith(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final textStyle = Theme.of(context).textTheme.labelSmall ?? const TextStyle();
          return textStyle.copyWith(overflow: TextOverflow.ellipsis);
        }),
      ),
      child: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_filled),
            label: translation(context: context, 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            label: translation(context: context, 'Communication'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.track_changes),
            label: translation(context: context, 'Tracking'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            label: translation(context: context, 'Lists'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            label: translation(context: context, 'More'),
          ),
        ],
      ),
    );
  }
}