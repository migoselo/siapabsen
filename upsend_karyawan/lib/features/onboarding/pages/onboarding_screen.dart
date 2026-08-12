import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingModel {
  final String image;
  final String title;
  final String description;

  OnboardingModel({
    required this.image,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingModel> _items = [
    OnboardingModel(
      image: 'assets/images/on1.svg',
      title: 'Presensi Modern dan Akurat',
      description:
          'Lakukan absensi hanya dengan foto selfie dan verifikasi lokasi secara real-time.',
    ),
    OnboardingModel(
      image: 'assets/images/on2.svg',
      title: 'Check-in di Kantor Cabang Manapun',
      description:
          'Lakukan presensi di seluruh cabang perusahaan, sesuai lokasi terdekat.',
    ),
    OnboardingModel(
      image: 'assets/images/on3.svg',
      title: 'Manajemen Cuti Simple',
      description:
          'Ajukan izin dan pantau status cuti Anda secara mudah tanpa ribet melalui aplikasi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2D365C);
    const Color textSecondaryColor = Color(0xFF9A9A9A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        SvgPicture.asset(
                          _items[index].image,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        Text(
                          _items[index].title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _items[index].description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentIndex < _items.length - 1
                      ? TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('has_seen_onboarding', true);
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          child: Text(
                            'Lewati',
                            style: GoogleFonts.plusJakartaSans(
                              color: textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const SizedBox(width: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? primaryColor
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  _currentIndex < _items.length - 1
                      ? TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Lanjut',
                            style: GoogleFonts.plusJakartaSans(
                              color: textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('has_seen_onboarding', true);
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          child: Text(
                            'Login',
                            style: GoogleFonts.plusJakartaSans(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
