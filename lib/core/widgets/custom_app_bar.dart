import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/lists/presentation/pages/pdf_preview_page.dart';
import 'package:faunty/core/utils/pdf_generator/base_pdf_layout.dart';
import 'package:faunty/core/utils/translation_helper.dart';

class TabAppBarConfig {
  final List<Widget>? actions;
  final Future<Map<String, List<Map<String, dynamic>>>> Function()? onGeneratePdf;
  final BasePdfLayout? pdfLayout;

  const TabAppBarConfig({
    this.actions,
    this.onGeneratePdf,
    this.pdfLayout,
  });
}

final tabAppBarConfigProvider = StateProvider.family<TabAppBarConfig?, String>((ref, tabId) => null);

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool useModern;
  final Future<Map<String, List<Map<String, dynamic>>>> Function()? onGeneratePdf;
  final BasePdfLayout? pdfLayout;
  final String? tabId;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.useModern = true,
    this.onGeneratePdf,
    this.pdfLayout,
    this.tabId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final activeConfig = tabId != null ? ref.watch(tabAppBarConfigProvider(tabId!)) : null;
    final List<Widget> allActions = (activeConfig?.actions ?? actions)?.toList() ?? [];
    final onGenPdf = activeConfig?.onGeneratePdf ?? onGeneratePdf;
    final pdfLay = activeConfig?.pdfLayout ?? pdfLayout;

    if (onGenPdf != null) {
      allActions.add(
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: translation(context: context, 'Generate PDF'),
          onPressed: () async {
            final data = await onGenPdf();

            if (!context.mounted) {
              return;
            }

            final hasContent = data.isNotEmpty &&
                data.values.any((rows) => rows.isNotEmpty);

            if (!hasContent) {
              showCustomSnackBar(
                context,
                translation(context: context, 'Nothing to export.'),
              );
              return;
            }

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PdfPreviewPage(
                  title: title,
                  data: data,
                  layout: pdfLay,
                ),
              ),
            );
          },
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final appBarBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final appBarBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Modern AppBar style
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: appBarBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: appBarBorderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: kToolbarHeight + 4,
              title: titleWidget ?? Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              actions: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: allActions.isEmpty
                        ? const SizedBox.shrink(key: ValueKey('empty_actions'))
                        : Row(
                            key: const ValueKey('has_actions'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...allActions,
                              const SizedBox(width: 12),
                            ],
                          ),
                  ),
                ),
              ],
              centerTitle: true,
              automaticallyImplyLeading: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}