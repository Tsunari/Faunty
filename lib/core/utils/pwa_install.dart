import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:faunty/core/utils/translation_helper.dart';

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