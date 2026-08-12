import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:upsend_karyawan/features/auth/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _drawingAnimation;

  bool _showFillAndText = false;
  bool _fadeOut = false;

  // Path SVG diurutkan dari posisi paling bawah ke paling atas
  // (Bottom-to-Top sequencing agar efek meng-ular bergerak dari bawah)
  final List<String> _svgPathsData = [
    // 1. Bottom Main Loop (Y: 43 - 151)
    'M86.3661 43.3325C88.5877 44.4215 90.6951 45.6585 92.8131 46.8925C93.2989 47.1734 93.785 47.4541 94.2712 47.7346C95.227 48.2861 96.1822 48.8384 97.1369 49.3914C98.7582 50.3295 100.389 51.255 102.022 52.1769C102.549 52.4747 103.075 52.7726 103.601 53.0704C103.993 53.2921 103.993 53.2921 104.393 53.5182C112.348 58.0205 112.348 58.0205 115.485 59.8533C117.76 61.1823 120.049 62.4924 122.34 63.8008C122.774 64.0488 123.208 64.2968 123.642 64.545C125.785 65.7702 127.929 66.9928 130.088 68.196C130.548 68.4531 130.548 68.4531 131.017 68.7154C131.57 69.0242 132.125 69.3315 132.681 69.6368C135.826 71.3944 138.594 73.2738 139.603 76.541C139.725 77.5597 139.755 78.577 139.783 79.6006C139.798 80.0568 139.798 80.0568 139.814 80.5223C139.905 83.3207 139.955 86.1201 139.994 88.9194C140.02 90.7976 140.058 92.6742 140.128 94.5516C140.195 96.3716 140.23 98.1902 140.243 100.011C140.253 100.702 140.274 101.393 140.307 102.084C140.545 107.327 140.545 107.327 138.987 108.91C137.467 110.019 135.787 110.774 133.991 111.486C132.575 112.081 131.28 112.836 129.968 113.588C129.67 113.752 129.372 113.916 129.066 114.084C127.364 115.022 125.665 115.963 123.968 116.907C120.656 118.748 117.333 120.572 114 122.385C110.843 124.102 107.697 125.833 104.553 127.568C101.064 129.494 97.5709 131.411 94.0679 133.316C90.773 135.109 87.4926 136.92 84.2181 138.741C81.7366 140.121 79.247 141.489 76.7576 142.858C75.9646 143.294 75.1724 143.732 74.3804 144.169C73.0409 144.909 71.6995 145.646 70.3572 146.382C69.7638 146.709 69.1711 147.036 68.579 147.364C67.6339 147.888 66.6866 148.409 65.7389 148.929C65.308 149.169 65.308 149.169 64.8684 149.414C62.035 150.961 58.9915 152.482 55.5515 151.895C52.5554 150.84 49.8908 149.268 47.2358 147.686C46.4327 147.213 45.6285 146.74 44.8245 146.268C44.5155 146.086 44.5155 146.086 44.2003 145.9C41.6068 144.374 38.9839 142.887 36.3616 141.399C35.0416 140.65 33.7249 139.897 32.412 139.139C32.0824 138.948 31.7528 138.758 31.4132 138.562C30.9608 138.294 30.9608 138.294 30.4992 138.021C30.2384 137.868 29.9777 137.714 29.709 137.556C27.9134 136.288 26.8768 134.53 26.2868 132.612C26.1916 131.573 26.2007 130.538 26.2095 129.496C26.2094 129.186 26.2093 128.876 26.2092 128.557C26.2097 127.536 26.215 126.515 26.2203 125.494C26.2216 124.785 26.2226 124.076 26.2232 123.366C26.2258 121.502 26.2325 119.638 26.2401 117.774C26.247 115.871 26.2501 113.968 26.2536 112.065C26.2608 108.333 26.2723 104.6 26.2868 100.868C27.3417 101.216 28.2848 101.584 29.2245 102.127C29.4559 102.26 29.6873 102.393 29.9257 102.53C30.1746 102.675 30.4235 102.82 30.68 102.969C30.9469 103.123 31.2138 103.277 31.4887 103.435C32.0681 103.769 32.647 104.104 33.2255 104.439C34.1437 104.971 35.0633 105.501 35.9832 106.031C39.0256 107.783 42.0628 109.542 45.0959 111.306C46.4681 112.104 47.8418 112.9 49.2157 113.695C49.8801 114.08 50.5436 114.467 51.2064 114.855C52.1341 115.397 53.0642 115.936 53.995 116.474C54.2712 116.637 54.5474 116.8 54.832 116.968C55.0871 117.114 55.3423 117.261 55.6051 117.412C55.826 117.541 56.0469 117.67 56.2745 117.802C56.9979 118.162 56.9979 118.162 58.2738 118.075C59.1067 117.724 59.1067 117.724 59.966 117.227C60.4622 116.953 60.4622 116.953 60.9685 116.674C61.3215 116.475 61.6745 116.277 62.0383 116.072C62.4043 115.87 62.7702 115.667 63.1473 115.458C63.8944 115.044 64.6408 114.629 65.3863 114.213C66.8328 113.406 68.2849 112.607 69.7373 111.808C70.1242 111.594 70.1242 111.594 70.519 111.376C72.7988 110.119 75.093 108.883 77.3883 107.647C79.3394 106.596 81.2833 105.535 83.2212 104.465C88.9373 101.31 94.681 98.1959 100.447 95.111C103.086 93.6969 105.705 92.2601 108.296 90.7812C107.418 89.9796 106.55 89.3238 105.487 88.7171C105.204 88.5545 104.921 88.3919 104.629 88.2244C104.324 88.0517 104.02 87.8789 103.706 87.7009C103.388 87.5187 103.07 87.3364 102.742 87.1487C101.723 86.5658 100.703 85.9849 99.6826 85.404C99.0106 85.0202 98.3387 84.6362 97.6668 84.2521C96.6781 83.6869 95.6893 83.1217 94.7002 82.5571C92.7183 81.4254 90.7425 80.2863 88.7733 79.1379C87.0136 78.1126 85.247 77.0966 83.4791 76.0821C83.181 75.9111 82.883 75.74 82.5759 75.5638C81.9559 75.208 81.3358 74.8523 80.7157 74.4966C75.5252 71.5188 70.3439 68.5299 65.1807 65.5162C61.7931 63.54 58.3813 61.6016 54.9299 59.711C52.6865 58.4756 50.5341 57.155 48.4055 55.7741C49.3369 54.8005 50.5688 54.3235 51.8461 53.7717C52.0914 53.664 52.3367 53.5563 52.5894 53.4453C53.4012 53.0895 54.2144 52.7363 55.0278 52.3832C55.5956 52.1354 56.1634 51.8875 56.7311 51.6394C57.9233 51.1191 59.1163 50.6 60.3098 50.0818C61.8285 49.4223 63.3455 48.7596 64.8619 48.0959C66.036 47.5825 67.211 47.0708 68.3864 46.5596C68.9453 46.3163 69.5039 46.0724 70.0622 45.828C81.1514 40.9779 81.1514 40.9779 86.3661 43.3325Z',
    // 2. Right Accent (Y: 91 - 108)
    'M109.998 91.0779C110.923 91.4534 111.739 91.9477 112.576 92.4534C112.951 92.6721 112.951 92.6721 113.333 92.8952C113.871 93.2102 114.409 93.527 114.945 93.8454C115.785 94.3428 116.63 94.8335 117.477 95.3224C119.269 96.3571 121.056 97.3978 122.844 98.439C123.746 98.9645 124.649 99.49 125.552 100.015C126.15 100.363 126.748 100.711 127.345 101.06C128.928 101.983 130.515 102.902 132.106 103.815C132.437 104.006 132.767 104.196 133.107 104.392C133.743 104.758 134.38 105.123 135.018 105.487C135.302 105.65 135.586 105.814 135.878 105.983C136.13 106.127 136.382 106.271 136.641 106.42C137.221 106.801 137.221 106.801 137.561 107.395C135.311 107.262 133.354 106.824 131.21 106.221C129.84 105.847 128.458 105.548 127.061 105.261C126.175 105.063 125.306 104.845 124.431 104.613C122.712 104.162 120.987 103.728 119.26 103.299C118.953 103.223 118.647 103.147 118.331 103.068C117.368 102.829 116.405 102.59 115.442 102.351C114.827 102.199 114.212 102.046 113.597 101.893C113.296 101.818 112.995 101.744 112.684 101.667C111.469 101.365 110.255 101.063 109.04 100.761C108.426 100.609 107.812 100.456 107.198 100.304C103.695 99.4357 100.2 98.558 96.7264 97.6046C96.7264 97.4088 96.7264 97.213 96.7264 97.0113C97.3543 96.6228 97.3543 96.6228 98.2325 96.1827C98.7108 95.9401 98.7108 95.9401 99.1988 95.6927C99.541 95.5221 99.8831 95.3514 100.236 95.1756C102.614 93.977 104.957 92.78 107.201 91.3965C108.236 90.9596 108.848 90.9705 109.998 91.0779Z',
    // 3. Right Vertical Edge (Y: 76 - 108)
    'M138.922 76.541C139.147 76.541 139.371 76.541 139.603 76.541C139.603 87.0165 139.603 97.4919 139.603 108.285C137.901 107.988 137.901 107.988 137.221 107.395C137.558 107.248 137.558 107.248 137.901 107.098C138.126 107.196 138.35 107.294 138.582 107.395C138.694 97.213 138.806 87.0313 138.922 76.541Z',
    // 4. Middle Left Accent (Y: 54 - 59)
    'M49.4264 54.884C49.5387 55.0798 49.651 55.2756 49.7667 55.4774C49.6544 55.6732 49.5421 55.869 49.4264 56.0707C49.6699 56.1464 49.9133 56.2222 50.1642 56.3002C51.1968 56.6901 52.0235 57.1669 52.9356 57.7395C53.2361 57.9269 53.5366 58.1143 53.8462 58.3073C54.185 58.5219 54.185 58.5219 54.5307 58.7408C54.4184 58.9366 54.3062 59.1324 54.1905 59.3341C53.2792 58.8137 52.3733 58.2865 51.4682 57.758C51.2085 57.6098 50.9488 57.4616 50.6812 57.309C50.3128 57.0924 50.3128 57.0924 49.9369 56.8715C49.7088 56.7394 49.4807 56.6074 49.2456 56.4713C49.0807 56.3391 48.9158 56.2069 48.7458 56.0707C48.7458 55.777 48.7458 55.4833 48.7458 55.1807C48.9704 55.0828 49.195 54.9849 49.4264 54.884Z',
    // 5. Left Middle Wave (Y: 55 - 67)
    'M33.4655 55.3554C33.8311 55.5716 34.1966 55.7878 34.5733 56.0105C34.7711 56.1262 34.9689 56.2419 35.1727 56.3611C35.5888 56.6056 36.0035 56.8521 36.4166 57.1004C37.0458 57.4784 37.6792 57.8505 38.3138 58.2216C41.6502 60.1906 41.6502 60.1906 42.9608 61.4108C40.3025 62.0274 37.6676 62.4241 34.9428 62.7273C32.5295 62.9967 30.1552 63.3239 27.7755 63.7656C24.5378 64.3655 21.2783 64.7698 17.998 65.1504C15.6329 65.4226 15.6329 65.4226 13.3053 65.8667C11.6476 66.2346 9.98817 66.4267 8.29402 66.6211C7.65672 66.6947 7.01956 66.7692 6.38256 66.8448C6.10407 66.8767 5.82558 66.9087 5.53865 66.9416C4.82816 67.0212 4.82816 67.0212 4.16803 67.3442C3.48759 67.3561 2.80671 67.3571 2.1263 67.3442C2.014 67.54 1.90171 67.7358 1.78601 67.9376C1.78601 67.6439 1.78601 67.3502 1.78601 67.0476C2.21608 66.8668 2.21608 66.8668 2.65484 66.6824C7.69757 64.5622 12.7355 62.4351 17.7381 60.2435C19.5653 59.4433 21.3947 58.6471 23.2241 57.8508C23.7699 57.6126 23.7699 57.6126 24.3268 57.3697C25.3183 56.939 26.3123 56.5133 27.3076 56.0893C27.5922 55.9649 27.8768 55.8404 28.17 55.7122C28.4328 55.6015 28.6957 55.4907 28.9665 55.3766C29.1902 55.2806 29.4139 55.1847 29.6444 55.0858C31.1113 54.6781 32.0932 54.7415 33.4655 55.3554Z',
    // 6. Top Wave (Y: 0 - 103)
    'M57.253 0C74.771 0 92.2891 0 110.338 0C109.955 2.67333 109.955 2.67333 109.64 3.82195C109.571 4.07665 109.501 4.33134 109.429 4.59376C109.321 4.98154 109.321 4.98154 109.211 5.37715C109.108 5.75461 109.108 5.75461 109.004 6.13969C108.595 7.62457 108.141 9.0937 107.654 10.5608C106.921 12.7735 106.254 14.9985 105.599 17.2294C105.405 17.8894 105.21 18.5492 105.014 19.2088C104.305 21.6146 103.621 24.0242 102.985 26.4456C102.615 27.8405 102.192 29.2164 101.746 30.5942C101.67 30.8261 101.595 31.058 101.518 31.297C101.453 31.4964 101.388 31.6959 101.322 31.9014C100.626 34.0779 99.9876 36.2678 99.3424 38.4559C99.249 38.7724 99.249 38.7724 99.1538 39.0952C98.7976 40.3035 98.4423 41.512 98.0876 42.7206C96.8609 41.6616 95.7066 40.5742 94.5996 39.4201C94.4374 39.2519 94.2752 39.0837 94.108 38.9104C91.6481 36.3542 89.2418 33.7608 86.8581 31.1504C85.3156 31.5643 83.8955 32.1049 82.4597 32.7397C82.233 32.8387 82.0063 32.9378 81.7727 33.0398C81.0254 33.3665 80.279 33.6949 79.5326 34.0233C79.005 34.2542 78.4773 34.4849 77.9496 34.7156C76.5574 35.3245 75.166 35.9346 73.7747 36.5452C71.3066 37.6282 68.8374 38.7095 66.3677 39.7898C66.102 39.906 65.8364 40.0223 65.5626 40.1421C61.7637 41.8036 57.9482 43.4284 54.1073 45.0152C51.8481 45.9495 49.6163 46.9291 47.3847 47.9123C43.3441 49.6853 39.2791 51.4086 35.1888 53.093C34.5415 53.364 33.9015 53.6479 33.2627 53.9338C32.412 54.2907 32.412 54.2907 31.7314 54.2907C31.7314 54.4865 31.7314 54.6823 31.7314 54.8841C31.9723 54.9601 32.2133 55.0361 32.4615 55.1144C33.5166 55.5087 34.4047 55.9879 35.3629 56.5389C35.549 56.6455 35.7351 56.752 35.9268 56.8617C36.5427 57.2148 37.1571 57.5699 37.7715 57.9249C38.2074 58.1754 38.6433 58.4257 39.0793 58.676C42.6837 60.7474 46.2711 62.8411 49.8595 64.9335C52.683 66.5793 55.5164 68.2023 58.4024 69.7642C62.9639 72.2531 67.4055 74.9113 71.8763 77.5215C73.4014 78.4117 74.9285 79.2992 76.4559 80.1864C77.2357 80.6396 78.0148 81.0938 78.7935 81.5485C79.2485 81.8139 79.7036 82.0793 80.1586 82.3446C80.5341 82.5638 80.5341 82.5638 80.9172 82.7874C82.446 83.6768 83.9831 84.5535 85.5288 85.4203C86.0556 85.7165 86.0556 85.7165 86.5931 86.0188C87.281 86.4049 87.97 86.7896 88.6603 87.1726C90.2703 88.0775 91.7068 88.9375 92.9832 90.1879C90.646 91.7543 88.2278 93.1247 85.7055 94.4486C83.3627 95.6822 81.0571 96.9633 78.755 98.2536C73.4084 101.244 73.4084 101.244 71.9917 102.018C71.6816 102.188 71.3715 102.359 71.052 102.534C69.6407 103.201 68.2659 103.623 66.6535 103.631C66.4192 103.636 66.185 103.641 65.9436 103.646C63.0953 103.291 60.9121 101.888 58.5948 100.502C57.5767 99.8933 56.5525 99.2924 55.529 98.6905C55.3261 98.5709 55.1232 98.4512 54.9141 98.328C53.1916 97.3146 51.4446 96.3385 49.6816 95.3796C47.6429 94.2683 45.627 93.1347 43.6314 91.9654C38.9713 89.238 34.2442 86.597 29.5377 83.9312C27.064 82.5299 24.5927 81.1257 22.1224 79.72C20.2087 78.6311 18.295 77.5423 16.3754 76.4614C15.7427 76.1008 15.1137 75.7352 14.4902 75.3628C12.8243 74.3779 11.2006 73.5033 9.37995 72.7611C2.20232 69.8091 2.20232 69.8091 0.789255 67.0157C-0.41989 63.5302 0.0484113 59.674 0.325191 56.0948C0.40185 54.9692 0.434402 53.8441 0.464778 52.717C0.527861 50.384 0.619506 48.0513 0.788975 45.7223C0.800119 45.5127 0.811264 45.3031 0.822746 45.0871C0.996472 43.0036 1.79925 41.3795 3.57741 39.9797C4.80079 39.1402 6.0984 38.5147 7.49388 37.9209C7.74717 37.8101 8.00047 37.6994 8.26145 37.5853C9.0931 37.2225 9.92706 36.864 10.7612 36.5056C11.3495 36.2501 11.9377 35.9944 12.5258 35.7385C14.0742 35.0655 15.6247 34.3961 17.1756 33.7275C18.4197 33.1904 19.6623 32.6507 20.9049 32.1109C26.3202 29.7581 31.7387 27.4132 37.2062 25.1536C41.0832 23.5475 44.9115 21.8554 48.7458 20.1736C54.0261 17.8576 59.3199 15.575 64.6629 13.3707C65.3192 13.0957 65.9685 12.808 66.6162 12.5181C67.4616 12.1635 67.4616 12.1635 68.1422 12.1635C66.7193 10.4405 65.1774 8.83307 63.5865 7.2283C62.232 5.86068 60.9104 4.47399 59.6058 3.06985C59.0513 2.47696 58.4854 1.89563 57.9123 1.31648C57.253 0.593341 57.253 0.593341 57.253 0Z',
    // 7. Small Left Top Accent (Y: 39 - 42)
    'M4.50831 39.4572C4.7329 39.5551 4.95749 39.653 5.18889 39.7538C5.02089 39.8969 4.85288 40.0399 4.67979 40.1872C4.46178 40.3746 4.24377 40.562 4.01915 40.7551C3.80202 40.9409 3.58488 41.1268 3.36117 41.3183C2.78005 41.806 2.78005 41.806 2.46659 42.4239C2.242 42.4239 2.01741 42.4239 1.78601 42.4239C2.27322 40.9372 3.14187 40.3636 4.50831 39.4572Z',
  ];

  late List<Path> _parsedPaths;

  @override
  void initState() {
    super.initState();

    _parsedPaths = _svgPathsData.map((d) => parseSvgPath(d)).toList();

    // 3. Pindah halaman tepat di detik ke 3
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateNext();
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _drawingAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _startSequence();
  }

  void _startSequence() async {
    // 1. Jalankan animasi menggambar jalur SVG
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _controller.forward();

    // 2. Transisi dari garis ke isian warna utuh (Fill) & munculkan teks "SiapAbsen"
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _showFillAndText = true);

    // 3. Efek Fade Out sebelum pindah halaman
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _fadeOut = true);

    // 4. Navigasi ke halaman Onboarding
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();

    // aktifkan jika ingin debug on boarding
    // if (kDebugMode) {
    //   await prefs.remove('has_seen_onboarding');
    // }

    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    await prefs.remove('auth_token');
    await prefs.remove('user_name');

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF2F3B69),
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _fadeOut ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: _fadeOut ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animasi Logo Meng-ular dari Bawah ke Atas
                  AnimatedBuilder(
                    animation: _drawingAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(size.width * 0.35, (size.width * 0.35) * (153 / 141)),
                        painter: MultiSvgPathPainter(
                          paths: _parsedPaths,
                          progress: _drawingAnimation.value,
                          isFilled: _showFillAndText,
                          viewBoxSize: const Size(141, 153),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Teks SiapAbsen dengan animasi Fade In & Slide Up
                  AnimatedOpacity(
                    opacity: _showFillAndText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      transform: Matrix4.translationValues(
                        0,
                        _showFillAndText ? 0 : 12,
                        0,
                      ),
                      child: const Text(
                        'SiapAbsen',
                        style: TextStyle(
                          fontFamily: 'jakarta',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
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

class MultiSvgPathPainter extends CustomPainter {
  final List<Path> paths;
  final double progress;
  final bool isFilled;
  final Size viewBoxSize;

  MultiSvgPathPainter({
    required this.paths,
    required this.progress,
    required this.isFilled,
    required this.viewBoxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / viewBoxSize.width;
    final double scaleY = size.height / viewBoxSize.height;
    final Matrix4 matrix = Matrix4.diagonal3Values(scaleX, scaleY, 1.0);

    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint accentFillPaint = Paint()
      ..color = const Color(0xFFF5F7FC)
      ..style = PaintingStyle.fill;

    final List<Rect> pathBounds = paths
        .map((path) => path.transform(matrix.storage).getBounds())
        .toList();
    final double minY = pathBounds.fold<double>(double.infinity,
        (value, rect) => value < rect.top ? value : rect.top);
    final double maxY = pathBounds.fold<double>(-double.infinity,
        (value, rect) => value > rect.bottom ? value : rect.bottom);
    final double height = (maxY - minY).clamp(1.0, double.infinity);

    for (int i = 0; i < paths.length; i++) {
      final Path scaledPath = paths[i].transform(matrix.storage);
      final Rect bounds = pathBounds[i];
      final double position = ((bounds.top - minY) / height).clamp(0.0, 1.0);
      final double start = position * 0.5;
      final double end = (start + 0.65).clamp(0.0, 1.0);
      final bool isAccent = i >= 1;

      if (isFilled) {
        canvas.drawPath(scaledPath, isAccent ? accentFillPaint : fillPaint);
        continue;
      }

      if (progress >= end) {
        canvas.drawPath(scaledPath, isAccent ? accentFillPaint : fillPaint);
      } else if (progress > start) {
        final double pathProgress =
            ((progress - start) / (end - start)).clamp(0.0, 1.0);

        for (final PathMetric metric in scaledPath.computeMetrics()) {
          final double extractLength = metric.length * pathProgress;
          final Path extractPath = metric.extractPath(0.0, extractLength);
          canvas.drawPath(extractPath, strokePaint);
        }

        if (pathProgress > 0.2) {
          final Color fillColor = isAccent
              ? const Color(0xFFF5F7FC)
              : Colors.white;
          final Color fillWithOpacity = fillColor.withAlpha(
              (pathProgress * 0.7 * 255).clamp(0, 255).toInt());
          final Paint currentFillPaint = Paint()
            ..color = fillWithOpacity
            ..style = PaintingStyle.fill;
          canvas.drawPath(scaledPath, currentFillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MultiSvgPathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isFilled != isFilled;
  }
}