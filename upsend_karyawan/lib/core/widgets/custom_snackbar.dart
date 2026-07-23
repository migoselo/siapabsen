import 'package:flutter/material.dart';

enum SnackbarType { info, success, error, warning }

class AppSnackbar {
  static const Map<SnackbarType, _SnackbarStyle> _styles = {
    SnackbarType.info: _SnackbarStyle(
      background: Color(0xFFE3F2FD),
      accent: Color(0xFF2196F3),
      title: 'Information!',
      icon: Icons.info_outline,
    ),
    SnackbarType.success: _SnackbarStyle(
      background: Color(0xFFE8F5E9),
      accent: Color(0xFF2E7D32),
      title: 'Success!',
      icon: Icons.check,
    ),
    SnackbarType.error: _SnackbarStyle(
      background: Color(0xFFFDE9E9),
      accent: Color(0xFFD32F2F),
      title: 'Error!',
      icon: Icons.close,
    ),
    SnackbarType.warning: _SnackbarStyle(
      background: Color(0xFFFFF8E1),
      accent: Color(0xFFF9A825),
      title: 'Warning!',
      icon: Icons.priority_high,
    ),
  };

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.success,
    String? titleOverride,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Tutup notifikasi sebelumnya dulu kalau masih ada, biar gak numpuk
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final style = _styles[type]!;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotification(
        style: style,
        message: message,
        titleOverride: titleOverride,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.info);

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.warning);
}

class _TopNotification extends StatefulWidget {
  final _SnackbarStyle style;
  final String message;
  final String? titleOverride;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.style,
    required this.message,
    required this.onDismiss,
    this.titleOverride,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: style.accent.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: style.accent, width: 2),
                    ),
                    child: Icon(style.icon, color: style.accent, size: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titleOverride ?? style.title,
                          style: TextStyle(
                            color: style.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackbarStyle {
  final Color background;
  final Color accent;
  final String title;
  final IconData icon;

  const _SnackbarStyle({
    required this.background,
    required this.accent,
    required this.title,
    required this.icon,
  });
}