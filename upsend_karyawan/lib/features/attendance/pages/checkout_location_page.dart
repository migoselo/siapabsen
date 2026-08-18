import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../attendance/models/location_model.dart';
import '../../attendance/repository/attendance_repository.dart';
import '../../attendance/widgets/location_card.dart';
import '../../attendance/widgets/searching_location_view.dart';
import '../../attendance/widgets/map_control_button.dart';
import 'checkout_camera_page.dart';

class CheckoutLocationPage extends StatefulWidget {
  final int attendanceId;

  const CheckoutLocationPage({super.key, required this.attendanceId});

  @override
  State<CheckoutLocationPage> createState() => _CheckoutLocationPageState();
}

class _CheckoutLocationPageState extends State<CheckoutLocationPage> {
  bool _isLoading = true;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  LocationModel? _selectedLocation;

  final MapController _mapController = MapController();
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyLocation();
  }

  Future<void> _loadNearbyLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedLocation = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif, mohon nyalakan lokasi.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen, ubah di Settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final repository = RepositoryProvider.of<AttendanceRepository>(context);
      final locations = await repository.getNearbyLocations(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (locations.isEmpty) {
        throw Exception(
          'Tidak ada lokasi kantor yang terdeteksi di sekitar Anda.',
        );
      }

      final selected = locations.first;
      if (!selected.withinRadius) {
        throw Exception(
          'Anda berada di luar radius ${selected.radiusMeter}m dari ${selected.name}.',
        );
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _selectedLocation = selected;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Check Out',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0), // <-- TAMBAHKAN
        child: Column(
          children: [
            const SizedBox(height: 25),
            const Text(
              'Sedang mencari lokasi Anda...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9A9A9A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Expanded(
              child: Align(
                alignment: Alignment(0, -0.3),
                child: SearchingLocationGate(),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _selectedLocation == null) {
      return _ErrorView(
        message: _errorMessage ?? 'Lokasi kantor tidak tersedia.',
        onRetry: _loadNearbyLocation,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (_latitude != null && _longitude != null)
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
                        initialCenter: latlong.LatLng(_latitude!, _longitude!),
                        initialZoom: 16,
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        _isSatelliteView
                            ? TileLayer(
                                urlTemplate:
                                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'com.upsend.karyawan',
                              )
                            : TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.upsend.karyawan',
                              ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latlong.LatLng(_latitude!, _longitude!),
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
                    Positioned(
                      top: 58,
                      right: 10,
                      child: MapControlButton(
                        icon: Icons.my_location,
                        onTap: () {
                          _mapController.move(
                            latlong.LatLng(_latitude!, _longitude!),
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
              'Lokasi Anda telah ditemukan',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 15),
          LocationCard(location: _selectedLocation!),
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
                    builder: (_) =>
                        CheckoutCameraPage(attendanceId: widget.attendanceId),
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
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // <-- BARU: bungkus dengan Padding sendiri
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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4B4B4B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(), // <-- UBAH: dari SizedBox(16) jadi Spacer, biar tombol selalu nempel bawah, samakan pola dgn checkin
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
            child: const Text(
              'Coba lagi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32), // <-- BARU: samakan dengan checkin
        ],
      ),
    );
  }
}
