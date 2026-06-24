import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/communication/presentation/pages/survey_page.dart';
import 'package:faunty/core/widgets/tab_page.dart';
import 'package:faunty/core/widgets/under_construction.dart';

final communicationTabIndexProvider = StateProvider<int?>((ref) => null);

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      tabs: [
        const TabMeta('Messenger', UnderConstructionPage(label: 'Messenger'), Icons.forum_outlined),
        const TabMeta('Announcements', UnderConstructionPage(label: 'Announcements'), Icons.campaign_outlined),
        const TabMeta('Surveys', SurveyPage(), Icons.thumbs_up_down_outlined),
        const TabMeta('Permissions', UnderConstructionPage(label: 'Permissions'), Icons.shield_moon_outlined),
        const TabMeta('Suggestion Box', UnderConstructionPage(label: 'Suggestion Box'), Icons.feedback_outlined),
        const TabMeta('Forum', UnderConstructionPage(label: 'Forum'), Icons.feed_outlined),
      ],
      tabIndexProvider: communicationTabIndexProvider,
      prefsKey: 'communication_last_tab_index',
    );
  }
}

// replaced by reusable UnderConstructionPage component