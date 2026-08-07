import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Warna yang disesuaikan dengan gambar
    const Color activeColor = Color(0xFF2E3A6E);
    const Color inactiveColor = Color(0xFF9E9E9E);
    const Color fabColor = Color(0xFF5163B7);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Background Bar
        Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Item 1: Beranda
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  label: 'Beranda',
                  iconPath: 'assets/images/Home.svg',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),

              // Item 2: Izin
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  label: 'Izin',
                  iconPath: 'assets/images/Document.svg',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),

              // Spacer untuk memberi ruang pada Tombol Presensi di tengah
              const SizedBox(width: 50),

              // Item 4: Riwayat
              _buildNavItem(
                index: 3,
                label: 'Riwayat',
                iconPath: 'assets/images/history.svg',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Item 5: Profil
              Expanded(
                child: _buildNavItem(
                  index: 4,
                  label: 'Profil',
                  iconPath: 'assets/images/Profile.svg',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
            ],
          ),
        ),

        // Item 3: Presensi (Tombol Lingkaran Tengah)
        Positioned(
          top: -24,
          child: GestureDetector(
            onTap: () => onTap(2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: fabColor,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'assets/images/faceid.svg',
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Presensi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: currentIndex == 2
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: currentIndex == 2 ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconPath,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = currentIndex == index;
    final Color currentColor = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            color: currentColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: currentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Backwards-compatible alias: jika ada kode yang masih memanggil `BottomNav`,
// kita sediakan wrapper ringan agar pemanggilan lama tidak error.
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
    return CustomBottomNavBar(currentIndex: activeIndex, onTap: onTap);
  }
}
