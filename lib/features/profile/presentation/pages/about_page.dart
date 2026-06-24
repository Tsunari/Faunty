import 'package:faunty/globals.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final secondary = theme.colorScheme.secondary;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: translation(context: context, 'About'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: onSurface.withAlpha(20),
                  child: Icon(Icons.info_outline, size: 64, color: primary),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  translation(context: context, 'Welcome to Faunty'),
                  style: textTheme.headlineMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                translation(context: context, 'Faunty is your modern management app, designed to simplify daily organization and communication for teams, communities, and organizations. Built with a focus on usability, security, and beautiful design, Faunty helps you stay connected and productive.'),
                style: textTheme.bodyLarge?.copyWith(color: onSurface),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(translation(context: context, 'Features'), style: textTheme.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      FeatureTile(icon: Icons.group, label: translation(context: context, 'Team & Community Management')),
                      FeatureTile(icon: Icons.calendar_today, label: translation(context: context, 'Weekly Program & Assignments')),
                      FeatureTile(icon: Icons.dining, label: translation(context: context, 'Catering & Cleaning Schedules')),
                      FeatureTile(icon: Icons.lock, label: translation(context: context, 'Secure Authentication')),
                      FeatureTile(icon: Icons.notifications_active, label: translation(context: context, 'Custom Notifications')),
                      FeatureTile(icon: Icons.phone_android, label: translation(context: context, 'Responsive & Mobile Friendly')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(translation(context: context, 'About the Project'), style: textTheme.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        translation(context: context, 'Faunty is built with Flutter and Firebase, ensuring fast performance and real-time updates. Our mission is to empower users with tools that make everyday management effortless and enjoyable.'),
                        style: textTheme.bodyMedium?.copyWith(color: onSurface),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<PackageInfo>(
                        future: getAppInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading version...');
                          }
                          if (snapshot.hasError) {
                            return Text('Version unavailable');
                          }
                          final info = snapshot.data;
                          return Text('Version: ${info?.version ?? '-'}');
                        },
                      ),
                      Text(
                        'Developed by Omar & Contributors',
                        style: textTheme.bodySmall?.copyWith(color: secondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  translation(context: context, 'Thank you for using Faunty!') + '\n' + translation(context: context, 'For feedback or support, contact us at talebelergfc@gmail.com'),
                  style: textTheme.bodyMedium?.copyWith(color: onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const FeatureTile({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}