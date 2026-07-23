import 'package:flutter/material.dart';

/// Toast types for different notification scenarios
enum ToastType { success, error, warning, info, failed }

/// Main function to show custom toast.
///
/// Pass either a [context] to look an [Overlay] up from, or an [overlayState]
/// directly — the latter is what context-free callers use, since
/// `Overlay.of(navigatorContext)` searches ancestors and so can never find the
/// navigator's own overlay. Does nothing if neither yields an overlay.
void showAppToast({
  BuildContext? context,
  OverlayState? overlayState,
  required String title,
  required String subtitle,
  ToastType type = ToastType.info,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay =
      overlayState ?? (context != null ? Overlay.maybeOf(context) : null);
  if (overlay == null) return;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _ToastOverlay(
      title: title,
      subtitle: subtitle,
      type: type,
      icon: icon,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

/// Extension to get properties for each toast type
extension _ToastTypeProps on ToastType {
  Color get accentColor {
    switch (this) {
      case ToastType.success:
        return const Color(0xFF22C55E); // Green
      case ToastType.error:
        return const Color(0xFFEF4444); // Red
      case ToastType.failed:
        return const Color(0xFFDC2626); // Dark Red
      case ToastType.warning:
        return const Color(0xFFF59E0B); // Orange
      case ToastType.info:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case ToastType.success:
        return Icons.check_circle_outline_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.failed:
        return Icons.cancel_outlined;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
    }
  }
}

/// Toast overlay widget
class _ToastOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final ToastType type;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.icon,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _progressAnimation;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Slide in from right
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.2, curve: Curves.easeOutCubic),
          ),
        );

    // Fade in
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2),
    );

    // Progress bar animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // Start animations
    _controller.forward();

    // Auto dismiss when animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.stop();
    widget.onDismiss();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Dismiss if dragged more than 100px or fast swipe
    if (_dragOffset.abs() > 100 ||
        details.velocity.pixelsPerSecond.dx.abs() > 500) {
      _dismiss();
    } else {
      // Reset position
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final type = widget.type;

    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: type.accentColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon container
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: type.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                widget.icon ?? type.defaultIcon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                      decoration: TextDecoration.none,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF6B7280),
                                      decoration: TextDecoration.none,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Close button
                            GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress bar at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 1 - _progressAnimation.value,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: type.accentColor,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
