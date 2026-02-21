import 'package:faunty/tools/translation_helper.dart';
import 'package:flutter/material.dart';
import 'quran_prayer_models.dart';

class QuranProgressSection extends StatelessWidget {
  final int currentJuz;
  final int currentPage;
  final int totalJuz;
  final int totalPages;
  final int juzStartPage;
  final int juzEndPage;
  final List<QuranProgressProfile> profiles;
  final String activeProfileId;
  final ValueChanged<String> onSelectProfile;
  final VoidCallback onAddProfile;
  final ValueChanged<String> onRenameProfile;
  final ValueChanged<String> onDeleteProfile;
  final Color accentColor;
  final ValueChanged<int> onJuzChanged;
  final ValueChanged<int> onPageChanged;
  final String subtitle;

  const QuranProgressSection({
    super.key,
    required this.currentJuz,
    required this.currentPage,
    required this.totalJuz,
    required this.totalPages,
    required this.juzStartPage,
    required this.juzEndPage,
    required this.profiles,
    required this.activeProfileId,
    required this.onSelectProfile,
    required this.onAddProfile,
    required this.onRenameProfile,
    required this.onDeleteProfile,
    required this.accentColor,
    required this.onJuzChanged,
    required this.onPageChanged,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressValue = totalPages == 0 ? 0.0 : currentPage / totalPages;
    final juzLength = (juzEndPage - juzStartPage + 1).clamp(1, totalPages);
    final juzIndex = (currentPage - juzStartPage + 1).clamp(1, juzLength);
    final pagesLeft = (juzEndPage - currentPage + 1).clamp(0, totalPages);
    final canDeleteProfile = profiles.length > 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  translation(context: context, 'Quran Progress'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${translation(context: context, 'Current Page')} $currentPage',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    translation(context: context, 'Progress profiles'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<_ProfileAction>(
                  onSelected: (value) {
                    switch (value) {
                      case _ProfileAction.rename:
                        onRenameProfile(activeProfileId);
                        break;
                      case _ProfileAction.delete:
                        onDeleteProfile(activeProfileId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ProfileAction.rename,
                      child: Text(
                        translation(context: context, 'Rename progress'),
                      ),
                    ),
                    if (canDeleteProfile)
                      PopupMenuItem(
                        value: _ProfileAction.delete,
                        child: Text(
                          translation(context: context, 'Delete progress'),
                        ),
                      ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final profile in profiles)
                  ChoiceChip(
                    label: Text(profile.name),
                    selected: profile.id == activeProfileId,
                    showCheckmark: false,
                    onSelected: (_) => onSelectProfile(profile.id),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(translation(context: context, 'Add progress')),
                  onPressed: onAddProfile,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: accentColor,
              backgroundColor: accentColor.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            _StepperRow(
              label: translation(context: context, 'Current Juz'),
              value: currentJuz,
              min: 1,
              max: totalJuz,
              onChanged: onJuzChanged,
            ),
            const SizedBox(height: 8),
            Text(
              '${translation(context: context, 'In this juz')} $juzIndex/$juzLength · ${translation(context: context, 'Pages left')} $pagesLeft',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            _SliderRow(
              label: translation(context: context, 'Current Page'),
              value: currentPage,
              min: 1,
              max: totalPages,
              onChanged: onPageChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentPage > 1
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: Text(translation(context: context, 'Previous page')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: currentPage < totalPages
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(translation(context: context, 'Next page')),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${translation(context: context, 'Juz starts at')} $juzStartPage · ${translation(context: context, 'Juz ends at')} $juzEndPage',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value / $max',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          onChanged: (nextValue) => onChanged(nextValue.round()),
        ),
      ],
    );
  }
}

enum _ProfileAction { rename, delete }
