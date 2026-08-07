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

class CheckinLocationPage extends StatefulWidget {
  const CheckinLocationPage({super.key});

  @override
  State<CheckinLocationPage> createState() => _CheckinLocationPageState();
}

class _CheckinLocationPageState extends State<CheckinLocationPage> {
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
          if (state.status == AttendanceStatus.loading &&
              state.nearbyLocations.isEmpty) {
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
                // Expanded(child: Center(child: _SearchingLocationGate())),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.3),
                    child: _SearchingLocationGate(),
                  ),
                ),
              ],
            );
          }

          final hasValidLocation =
              state.selectedLocation != null &&
              state.selectedLocation!.withinRadius;

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
                      child: FlutterMap(
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
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.upsend.karyawan',
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
                    ),
                  ),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _buildSubtitle(state),
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                if (state.selectedLocation != null)
                  LocationCard(location: state.selectedLocation!),

                if (state.status == AttendanceStatus.failure)
                  _ErrorBox(message: state.errorMessage),

                if (state.status == AttendanceStatus.success &&
                    state.nearbyLocations.isEmpty)
                  const _EmptyLocationBox(),

                // Box besar "di luar radius" DIHAPUS — cukup card + subtitle
                const Spacer(),

                // Tombol "Lanjut ke kamera" -> DIKUNCI kalau di luar radius
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (hasValidLocation &&
                            state.status != AttendanceStatus.loading)
                        ? const Color(0xFF2F3B69)
                        : const Color(0xFF9A9A9A),
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed:
                      (!hasValidLocation ||
                          state.status == AttendanceStatus.loading)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckinCameraPage(),
                            ),
                          );
                        },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Lanjut",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol "Coba lagi" -> memicu FetchNearbyLocations
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.2),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: state.status == AttendanceStatus.loading
                      ? null
                      : () {
                          context.read<AttendanceBloc>().add(
                            FetchNearbyLocations(),
                          );
                        },
                  child: state.status == AttendanceStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF006D4C),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, color: Colors.black, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Coba lagi",
                              style: TextStyle(
                                color: Colors.black,
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
        },
      ),
    );
  }

  String _buildSubtitle(AttendanceState state) {
    if (state.status == AttendanceStatus.failure) {
      return "Gagal mendeteksi lokasi";
    }
    if (state.selectedLocation != null) {
      return state.selectedLocation!.withinRadius
          ? "Lokasi Anda telah ditemukan"
          : "Anda di luar jangkauan lokasi";
    }
    return "Mencari lokasi Anda...";
  }
}

class _ErrorBox extends StatelessWidget {
  final String? message;
  const _ErrorBox({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? "Terjadi kesalahan saat mengambil lokasi.",
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLocationBox extends StatelessWidget {
  const _EmptyLocationBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_off_outlined, color: Color(0xFFB45309)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tidak ada lokasi kantor yang terdeteksi di sekitar Anda.",
              style: TextStyle(color: Color(0xFFB45309), fontSize: 13),
            ),
          ),
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
          // Cincin putus-putus (statis, gak ikut denyut)
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
          // Lingkaran dalam + pin utama -> ini yang "berdetak"
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
          // Pin kecil kiri atas
          const Positioned(
            top: 20,
            left: 25,
            child: _MiniPinBadge(color: strokeColor),
          ),
          // Pin kecil kanan atas
          const Positioned(
            top: 30,
            right: 30,
            child: _MiniPinBadge(color: fillColor),
          ),
          // Pin kecil kanan bawah
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
