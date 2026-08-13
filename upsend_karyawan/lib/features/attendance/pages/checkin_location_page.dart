import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../widgets/location_card.dart';
import 'checkin_camera_page.dart';
import 'checkin_success_page.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:flutter_map/flutter_map.dart' show MapController;

class CheckinLocationPage extends StatefulWidget {
  const CheckinLocationPage({super.key});

  @override
  State<CheckinLocationPage> createState() => _CheckinLocationPageState();
}

class _CheckinLocationPageState extends State<CheckinLocationPage> {
  final MapController _mapController = MapController();
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(FetchNearbyLocations());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 25 + 24 + 25,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Check In",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final hasValidLocation =
              state.selectedLocation != null &&
              state.selectedLocation!.withinRadius;

          // Masih loading -> tampilkan animasi pencarian
          if (state.status == AttendanceStatus.loading) {
            return const Column(
              children: [
                SizedBox(height: 25),
                Text(
                  "Sedang mencari lokasi Anda...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment(0, -0.3),
                    child: _SearchingLocationGate(),
                  ),
                ),
              ],
            );
          }

          // Belum loading, TAPI belum ketemu lokasi valid (gagal / di luar radius / kosong)
          // -> TETAP di halaman ini, tampilkan pesan + tombol "Coba lagi"
          if (!hasValidLocation) {
            return _LocationRetryView(
              state: state,
              onRetry: () {
                context.read<AttendanceBloc>().add(FetchNearbyLocations());
              },
            );
          }

          // Sudah ketemu lokasi valid & dalam radius -> tampilkan peta + tombol Lanjut
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                const SizedBox(height: 16),

                if (state.latitude != null && state.longitude != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: latlong.LatLng(
                                state.latitude!,
                                state.longitude!,
                              ),
                              initialZoom: 16,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              // Tampilan jalan (OpenStreetMap) atau satelit (Esri),
                              // tergantung _isSatelliteView
                              _isSatelliteView
                                  ? TileLayer(
                                      urlTemplate:
                                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                      userAgentPackageName:
                                          'com.upsend.karyawan',
                                    )
                                  : TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.upsend.karyawan',
                                    ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: latlong.LatLng(
                                      state.latitude!,
                                      state.longitude!,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFE11D48),
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Tombol toggle jalan/satelit (pojok kanan atas)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _MapControlButton(
                              icon: _isSatelliteView
                                  ? Icons.map_outlined
                                  : Icons.satellite_alt_outlined,
                              onTap: () {
                                setState(() {
                                  _isSatelliteView = !_isSatelliteView;
                                });
                              },
                            ),
                          ),

                          // Tombol "lokasi saya" (di bawah tombol toggle)
                          Positioned(
                            top: 58,
                            right: 10,
                            child: _MapControlButton(
                              icon: Icons.my_location,
                              onTap: () {
                                _mapController.move(
                                  latlong.LatLng(
                                    state.latitude!,
                                    state.longitude!,
                                  ),
                                  16,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 15),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Lokasi Anda telah ditemukan",
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                LocationCard(location: state.selectedLocation!),

                const Spacer(),

                // Tombol "Lanjut" -> TANPA tombol "Coba lagi" lagi di sini
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3B69),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckinCameraPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Lanjut",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================================================
// Tampilan ketika lokasi GAGAL ditemukan / DI LUAR radius / TIDAK ADA lokasi
// terdeteksi sama sekali. User TETAP di halaman ini, tombol "Coba lagi"
// ada di sini, BUKAN di halaman peta.
// ==========================================================================
class _LocationRetryView extends StatelessWidget {
  final AttendanceState state;
  final VoidCallback onRetry;

  const _LocationRetryView({required this.state, required this.onRetry});

  String _title() {
    if (state.status == AttendanceStatus.failure) {
      return "Gagal mendeteksi lokasi";
    }
    if (state.selectedLocation != null &&
        !state.selectedLocation!.withinRadius) {
      return "Anda di luar jangkauan lokasi";
    }
    return "Lokasi kantor tidak ditemukan";
  }

  String _subtitle() {
    if (state.status == AttendanceStatus.failure) {
      return state.errorMessage?.replaceFirst('Exception: ', '') ??
          "Terjadi kesalahan saat mengambil lokasi.";
    }
    if (state.selectedLocation != null &&
        !state.selectedLocation!.withinRadius) {
      final loc = state.selectedLocation!;
      return "Jarak Anda ${loc.distance.toStringAsFixed(0)}m dari ${loc.name} (radius maksimal ${loc.radiusMeter}m). Mendekatlah ke lokasi kantor.";
    }
    return "Tidak ada lokasi kantor yang terdeteksi di sekitar Anda.";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFEF2F2),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              color: Color(0xFFDC2626),
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _title(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3B69),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            onPressed: onRetry,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "Coba lagi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SearchingLocationGate extends StatefulWidget {
  const _SearchingLocationGate();

  @override
  State<_SearchingLocationGate> createState() => _SearchingLocationGateState();
}

class _SearchingLocationGateState extends State<_SearchingLocationGate> {
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showLoading = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoading) {
      return const SizedBox.shrink();
    }
    return const _SearchingLocationView();
  }
}

class _SearchingLocationView extends StatefulWidget {
  const _SearchingLocationView();

  @override
  State<_SearchingLocationView> createState() => _SearchingLocationViewState();
}

class _SearchingLocationViewState extends State<_SearchingLocationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  static const Color strokeColor = Color(0xFF344997);
  static const Color fillColor = Color(0xFF4F8BFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DottedBorder(
            options: CircularDottedBorderOptions(
              color: strokeColor,
              strokeWidth: 2,
              dashPattern: const [6, 5],
            ),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fillColor.withOpacity(0.08),
              ),
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fillColor.withOpacity(0.15),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: strokeColor, width: 2),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: strokeColor,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 20,
            left: 25,
            child: _MiniPinBadge(color: strokeColor),
          ),
          const Positioned(
            top: 30,
            right: 30,
            child: _MiniPinBadge(color: fillColor),
          ),
          const Positioned(
            bottom: 35,
            right: 20,
            child: _MiniPinBadge(color: Color(0xFF06B6D4)),
          ),
        ],
      ),
    );
  }
}

class _MiniPinBadge extends StatelessWidget {
  final Color color;
  const _MiniPinBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.location_on, color: color, size: 16),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF2F3B69), size: 20),
        ),
      ),
    );
  }
}