import 'package:flutter/material.dart';

// =====================================================================
// SOURCE OF TRUTH — spesifikasi Figma persis
// =====================================================================
const Color _kBorder = Color(0xFFBCCAC0);
const Color _kBackground = Color(0xFFFFFFFF);
const Color _kSelectedBg = Color(0xFF006948);
const Color _kIconActive = Color(0xFFFFFFFF);
const Color _kIconInactive = Color(0xFF3D4A42);

const double _kHeight = 74;
const double _kBorderTopWidth = 2;
const double _kSelectedRadius = 12;
const double _kIconSize = 24;
const double _kLabelFontSize = 16;
const FontWeight _kLabelFontWeight = FontWeight.w400; // regular
const double _kHorizontalPadding = 56.66;
const double _kVerticalPadding = 8;
const double _kSpacingAntarMenu = 60;

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

class BottomNav extends StatelessWidget {
  final List<BottomNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kBackground,
        border: Border(top: BorderSide(color: _kBorder, width: _kBorderTopWidth)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _kHorizontalPadding,
        vertical: _kVerticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _BottomNavItemWidget(
              item: items[i],
              isActive: i == activeIndex,
              onTap: () => onTap(i),
            ),
            if (i != items.length - 1) const SizedBox(width: _kSpacingAntarMenu),
          ],
        ],
      ),
    );
  }
}

class _BottomNavItemWidget extends StatelessWidget {
  final BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? _kIconActive : _kIconInactive;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: _kIconSize, color: iconColor),
        const SizedBox(height: 4), // NOTE: spacing icon->label gak ada di spec, estimasi
        Text(
          item.label,
          style: TextStyle(
            fontSize: _kLabelFontSize,
            fontWeight: _kLabelFontWeight,
            color: iconColor,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: isActive
          ? Container(
              // NOTE: padding internal pill ini gak disebutkan di spec,
              // estimasi dari screenshot — sesuaikan lagi kalau meleset.
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _kSelectedBg,
                borderRadius: BorderRadius.circular(_kSelectedRadius),
              ),
              child: content,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: content,
            ),
    );
  }
}