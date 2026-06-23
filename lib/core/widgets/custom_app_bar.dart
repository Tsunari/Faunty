import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/lists/presentation/pages/pdf_preview_page.dart';
import 'package:faunty/core/utils/pdf_generator/base_pdf_layout.dart';
import 'package:faunty/core/utils/translation_helper.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool useModern;
  final Future<Map<String, List<Map<String, dynamic>>>> Function()? onGeneratePdf;
  final BasePdfLayout? pdfLayout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.useModern = true,
    this.onGeneratePdf,
    this.pdfLayout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<Widget> allActions = actions?.toList() ?? [];
    if (onGeneratePdf != null) {
      allActions.add(
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: translation(context: context, 'Generate PDF'),
          onPressed: () async {
            final data = await onGeneratePdf!();

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
                  layout: pdfLayout,
                ),
              ),
            );
          },
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final appBarBgColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final appBarBorderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    // Modern AppBar style
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
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
                  color: isDark ? Colors.black45 : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: titleWidget ?? Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              actions: allActions.isNotEmpty ? allActions : null,
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