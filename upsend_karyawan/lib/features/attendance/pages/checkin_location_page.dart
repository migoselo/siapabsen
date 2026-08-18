import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../repository/attendance_repository.dart';
import '../widgets/location_card.dart';
import '../widgets/searching_location_view.dart';
import '../widgets/map_control_button.dart';
import 'checkin_camera_page.dart';

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
                    child: SearchingLocationGate(),
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
                            child: MapControlButton(
                              icon: _isSatelliteView
                                  ? Icons.map_outlined
                                  : Icons.satellite,
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
                            child: MapControlButton(
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

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3B69),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final attendanceRepository = AttendanceRepository();
                    final hasRegisteredFace = await attendanceRepository
                        .checkFaceRegistrationStatus();

                    if (!hasRegisteredFace && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Anda belum mendaftar wajah. Silakan daftar wajah di profil terlebih dahulu.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckinCameraPage(),
                        ),
                      );
                    }
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
    return "Gagal mendeteksi lokasi";
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
    return "Gagal mendeteksi lokasi kantor di sekitar Anda.";
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
