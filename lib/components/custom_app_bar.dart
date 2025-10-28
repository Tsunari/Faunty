import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:faunty/tools/pdf_generator/base_pdf_layout.dart';
import 'package:faunty/tools/pdf_generator/pdf_generator.dart';
import 'package:faunty/tools/translation_helper.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool useModern;
  final Future<Map<String, List<Map<String, dynamic>>>> Function()? onGeneratePdf;
  final BasePdfLayout? pdfLayout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.useModern = true,
    this.onGeneratePdf,
    this.pdfLayout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!useModern) {
      // Old AppBar style
      return AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
      );
    }

    List<Widget> allActions = actions?.toList() ?? [];
    if (onGeneratePdf != null) {
      allActions.add(
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: translation(context: context, 'Generate PDF'),
          onPressed: () async {
            final data = await onGeneratePdf!();
            await PdfGenerator.generateAndPrintPdf(title: title, data: data, layout: pdfLayout);
          },
        ),
      );
    }

    // Modern AppBar style
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
