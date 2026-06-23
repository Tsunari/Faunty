import 'dart:math' as math;

import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';

/// Reusable under-construction page with a small, stylish animation.
class UnderConstructionPage extends StatefulWidget {
  final String label;
  const UnderConstructionPage({required this.label, super.key});

  @override
  State<UnderConstructionPage> createState() => _UnderConstructionPageState();
}

class _UnderConstructionPageState extends State<UnderConstructionPage>
  with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _scaleAnim;
  late final AnimationController _lineCtrl;

  @override
  void initState() {
    super.initState();
    // single controller with reverse repeat; drive several derived animations
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    // dedicated controller for the dotted "road" animation (loops forward only)
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _slideAnim = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    ));

    _fadeAnim = Tween<double>(begin: 0.75, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    ));

    _rotateAnim = Tween<double>(begin: -0.12, end: 0.12).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    ));

    _scaleAnim = Tween<double>(begin: 0.98, end: 1.04).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
  _lineCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final primary = colorScheme.primary;
  final secondary = colorScheme.secondary;
  final onPrimary = colorScheme.onPrimary;
  final onSurface = colorScheme.onSurface;
  final surface = colorScheme.surface;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                // small floating accents (parallax) positions
                final double floatA = math.sin(_ctrl.value * math.pi * 2) * 10;
                final double floatB = math.cos((_ctrl.value + 0.35) * math.pi * 2) * 8;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // soft surface background card
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surface.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // floating glyph A (top-left, frames the icon)
                    Positioned(
                      left: 18,
                      top: 18 + floatA,
                      child: Opacity(
                        opacity: 0.95,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primary.withOpacity(0.18), secondary.withOpacity(0.12)],
                            ),
                          ),
                          child: Center(child: Icon(Icons.build_rounded, size: 20, color: onPrimary.withOpacity(0.95))),
                        ),
                      ),
                    ),

                    // floating glyph B (top-right, symmetrical balance)
                    Positioned(
                      right: 18,
                      top: 22 + floatB,
                      child: Opacity(
                        opacity: 0.9,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [secondary.withOpacity(0.16), primary.withOpacity(0.12)],
                            ),
                          ),
                          child: Center(child: Icon(Icons.settings_suggest_rounded, size: 20, color: onPrimary.withOpacity(0.95))),
                        ),
                      ),
                    ),

                    // big pulsing construction icon with shimmer shader
                    Transform.scale(
                      scale: _scaleAnim.value,
                      child: Transform.rotate(
                        angle: _rotateAnim.value,
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment(-1.0 + _slideAnim.value, -1),
                              end: Alignment(1.0 + _slideAnim.value, 1),
                              colors: [
                                primary.withOpacity(0.95),
                                onPrimary.withOpacity(0.98),
                                secondary.withOpacity(0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(rect);
                          },
                          child: Opacity(
                            opacity: _fadeAnim.value,
                            child: Icon(
                              Icons.construction_rounded,
                              size: 132,
                              color: onSurface.withOpacity(0.98),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // subtle decorative dotted path under icon
                    Positioned(
                      bottom: 34,
                      left: 36,
                      right: 36,
                      child: SizedBox(
                        height: 12,
                        // animate the dotted road with its own forward-looping controller
                        child: AnimatedBuilder(
                          animation: _lineCtrl,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _DottedLinePainter(primary.withOpacity(0.18), _lineCtrl.value),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'This page is under construction',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),

          // small feature bullets (what's coming)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconBubble(icon: Icons.timeline_rounded, color: primary),
                const SizedBox(width: 18),
                _IconBubble(icon: Icons.group_rounded, color: primary),
                const SizedBox(width: 18),
                _IconBubble(icon: Icons.notifications_active_rounded, color: primary),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // staggered dot loader (animated)
          _StaggeredDots(controller: _ctrl, color: primary),
          const SizedBox(height: 12),

          // CTA
          ElevatedButton.icon(
            onPressed: () {
              showCustomSnackBar(context, 'No I will not');
            },
            icon: const Icon(Icons.notifications_none_outlined),
            label: const Text('Notify me when ready'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double phase;
  _DottedLinePainter(this.color, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round;
    final dashWidth = 6.0;
    final gap = 8.0;
    double x = 0.0 + (phase * (dashWidth + gap));
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + dashWidth, size.height / 2), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) => oldDelegate.phase != phase || oldDelegate.color != color;
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 6)),
        ],
      ),
      child: Icon(icon, size: 26, color: color),
    );
  }
}

class _StaggeredDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  const _StaggeredDots({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (controller.value + i * 0.18) % 1.0;
              final scale = 0.7 + (math.sin(phase * math.pi * 2).abs() * 0.5);
              final opacity = 0.5 + (math.sin(phase * math.pi * 2).abs() * 0.5);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color.withOpacity(0.95), shape: BoxShape.circle),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}