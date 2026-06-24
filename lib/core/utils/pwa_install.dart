import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/glass_container.dart';
import 'package:faunty/core/utils/local_storage_helper.dart';
import 'dart:js' as js;

/// Wrapper utilities around the pwa_install package
class AppPWAInstall {
	static final AppPWAInstall _instance = AppPWAInstall._internal();
	factory AppPWAInstall() => _instance;
	AppPWAInstall._internal();

	bool _initialized = false;

	void setup({VoidCallback? onInstalled}) {
		if (_initialized) return;
		_initialized = true;
		if (!kIsWeb) return;
		PWAInstall().setup(installCallback: onInstalled);
	}

	bool get canInstall => kIsWeb && PWAInstall().installPromptEnabled;
	void promptInstall() => PWAInstall().promptInstall_();
}

/// Minimal, theme-friendly button that appears only when install is available
class PwaInstallButtonSimple extends StatefulWidget {
	final double maxWidth;
	final EdgeInsetsGeometry? margin;
	const PwaInstallButtonSimple({super.key, this.maxWidth = 400, this.margin});

	@override
	State<PwaInstallButtonSimple> createState() => _PwaInstallButtonSimpleState();
}

class _PwaInstallButtonSimpleState extends State<PwaInstallButtonSimple> {
	bool _show = false;
	bool _checking = true;

	@override
	void initState() {
		super.initState();
		// Initialize once and then probe availability shortly after
		AppPWAInstall().setup(onInstalled: () {
			if (!mounted) return;
			setState(() {
				_show = false;
			});
		});

		Future.delayed(const Duration(milliseconds: 200), _refresh);
		Future.delayed(const Duration(seconds: 1), _refresh);
		Future.delayed(const Duration(seconds: 2), _refresh);
	}

	void _refresh() {
		if (!mounted) return;
		setState(() {
			_show = AppPWAInstall().canInstall;
			_checking = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		if (!kIsWeb) return const SizedBox.shrink();
		if (_checking) {
			return Padding(
				padding: widget.margin ?? const EdgeInsets.only(top: 12),
				child: Center(
					child: ConstrainedBox(
						constraints: BoxConstraints(maxWidth: widget.maxWidth),
						child: const LinearProgressIndicator(minHeight: 2),
					),
				),
			);
		}
		if (!_show) return const SizedBox.shrink();

		return Padding(
			padding: widget.margin ?? const EdgeInsets.only(top: 12),
			child: Center(
				child: ConstrainedBox(
					constraints: BoxConstraints(maxWidth: widget.maxWidth),
					child: OutlinedButton.icon(
						onPressed: () {
							try {
								AppPWAInstall().promptInstall();
							} catch (e) {
								final msg = translation(
									context: context,
									'To install, use your browser\'s menu and select "Install app"',
								);
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(content: Text(msg)),
								);
							}
						},
						icon: const Icon(Icons.download_rounded),
						label: Text(translation(context: context, 'Install App')),
						style: OutlinedButton.styleFrom(
							padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
							shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
							side: BorderSide(
								color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
							),
						),
					),
				),
			),
		);
	}
}

/// Even more minimal inline button to place inside a Row
class PwaInstallInlineButton extends StatefulWidget {
	const PwaInstallInlineButton({super.key});

	@override
	State<PwaInstallInlineButton> createState() => _PwaInstallInlineButtonState();
}

class _PwaInstallInlineButtonState extends State<PwaInstallInlineButton> {
	bool _show = false;

	@override
	void initState() {
		super.initState();
		AppPWAInstall().setup(onInstalled: () {
			if (!mounted) return;
			setState(() => _show = false);
		});
		Future.delayed(const Duration(milliseconds: 150), _refresh);
		Future.delayed(const Duration(seconds: 1), _refresh);
	}

	void _refresh() {
		if (!mounted) return;
		setState(() => _show = AppPWAInstall().canInstall);
	}

	@override
	Widget build(BuildContext context) {
		if (!kIsWeb || !_show) return const SizedBox.shrink();
		return TextButton.icon(
			onPressed: () {
				try {
					AppPWAInstall().promptInstall();
				} catch (e) {
					final msg = translation(
						context: context,
						'To install, use your browser\'s menu and select "Install app"',
					);
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text(msg)),
					);
				}
			},
			icon: const Icon(Icons.download_rounded, size: 18),
			label: Text(
				translation(context: context, 'Install app'),
				style: const TextStyle(fontSize: 14),
			),
			style: TextButton.styleFrom(
				padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
				foregroundColor: Theme.of(context).colorScheme.primary,
			),
		);
	}
}

class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> with SingleTickerProviderStateMixin {
  bool _dismissed = true; // start hidden to avoid flashing
  bool _showPrompt = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _checkStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _isStandalone() {
    if (!kIsWeb) return false;
    try {
      final isStandaloneMode = js.context.callMethod('matchMedia', ['(display-mode: standalone)'])['matches'] == true;
      final navigator = js.context['navigator'];
      final isAppleStandalone = navigator != null && navigator['standalone'] == true;
      return isStandaloneMode || isAppleStandalone;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkStatus() async {
    if (!kIsWeb) return;
    if (_isStandalone()) return;

    final alreadyDismissed = await LocalStorageHelper.getPwaPromptDismissed();
    if (alreadyDismissed) return;

    // Wait short delay for pwa_install initialization
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Detect if we can prompt (Android/Chrome/etc) OR if it is iOS (Safari)
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final canPrompt = AppPWAInstall().canInstall;

    if (canPrompt || isIos) {
      setState(() {
        _dismissed = false;
        _showPrompt = canPrompt;
      });
      _animController.forward();
    } else {
      // Setup listener/timer to probe
      for (int delay in [1000, 2000, 4000]) {
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted) return;
        if (AppPWAInstall().canInstall) {
          setState(() {
            _dismissed = false;
            _showPrompt = true;
          });
          _animController.forward();
          break;
        }
      }
    }
  }

  void _dismiss() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _dismissed = true;
        });
      }
    });
    LocalStorageHelper.setPwaPromptDismissed(true);
  }

  void _triggerInstall(BuildContext context) {
    if (_showPrompt) {
      try {
        AppPWAInstall().promptInstall();
      } catch (e) {
        _showIosGuide(context);
      }
    } else {
      _showIosGuide(context);
    }
  }

  void _showIosGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return GlassContainer(
          borderRadius: 24.0,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translation(context: context, 'Install App'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                translation(
                  context: context,
                  'To install Faunty on your iPhone/iPad, please follow these steps:',
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              _buildStepRow(
                context,
                '1',
                translation(context: context, 'Tap the Share button in Safari (at the bottom/top of the screen).'),
                Icons.ios_share,
              ),
              const SizedBox(height: 12),
              _buildStepRow(
                context,
                '2',
                translation(context: context, 'Scroll down and tap "Add to Home Screen".'),
                Icons.add_box_outlined,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(translation(context: context, 'Got it')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepRow(BuildContext context, String number, String text, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.3),
              ),
              const SizedBox(height: 4),
              Icon(icon, size: 20, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnim,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
          child: GlassContainer(
            borderRadius: 20,
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translation(context: context, 'Install Faunty'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              translation(
                                context: context,
                                'Add to your home screen for quick, offline access.',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _dismiss,
                      child: Text(
                        translation(context: context, 'Later'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => _triggerInstall(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(translation(context: context, 'Install')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}