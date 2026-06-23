import 'package:flutter/material.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool floating;
  final bool pinned;
  final double expandedHeight;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.floating = false,
    this.pinned = false,
    this.expandedHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
      title: Text(title),
      actions: actions,
      floating: floating,
      expandedHeight: expandedHeight,
      flexibleSpace: expandedHeight > kToolbarHeight
          ? FlexibleSpaceBar(
              title: Text(title),
            )
          : null,
    );
  }
}
