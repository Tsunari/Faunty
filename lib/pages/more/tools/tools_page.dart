import 'package:faunty/components/custom_app_bar.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'quran_prayer/quran_prayer_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  bool _isNavigating = false;

  Future<void> _openTool(Widget Function() builder) async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => builder()));

    if (!mounted) return;
    setState(() {
      _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tools = <_ToolItem>[
      _ToolItem(
        title: translation(context: context, 'Quran and Prayers'),
        subtitle: translation(
          context: context,
          'Quran pages, juz, and prayers',
        ),
        icon: Icons.menu_book_outlined,
        builder: () => const QuranPrayerPage(),
      ),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'Tools'),
        useModern: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _ToolCard(
            tool: tool,
            accentColor: colorScheme.primary,
            onTap: () => _openTool(tool.builder),
          );
        },
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.tool,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.5);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.12),
                accentColor.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tool.icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
