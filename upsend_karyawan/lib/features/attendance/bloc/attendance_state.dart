import 'dart:io';
import '../models/location_model.dart';
import '../models/attendance_model.dart';

enum AttendanceStatus { initial, loading, success, failure }

class AttendanceState {
  final AttendanceStatus status;
  final int currentStep; // 1: Lokasi, 2: Kamera, 3: Selesai
  final List<LocationModel> nearbyLocations;
  final LocationModel? selectedLocation;
  final double? latitude;
  final double? longitude;
  final File? capturedPhoto;
  final AttendanceModel? attendanceResult;
  final String? errorMessage;

  AttendanceState({
    this.status = AttendanceStatus.initial,
    this.currentStep = 1,
    this.nearbyLocations = const [],
    this.selectedLocation,
    this.latitude,
    this.longitude,
    this.capturedPhoto,
    this.attendanceResult,
    this.errorMessage,
  });

  AttendanceState copyWith({
    AttendanceStatus? status,
    int? currentStep,
    List<LocationModel>? nearbyLocations,
    LocationModel? selectedLocation,
    double? latitude,
    double? longitude,
    File? capturedPhoto,
    AttendanceModel? attendanceResult,
    String? errorMessage,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      nearbyLocations: nearbyLocations ?? this.nearbyLocations,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedPhoto: capturedPhoto ?? this.capturedPhoto,
      attendanceResult: attendanceResult ?? this.attendanceResult,
      errorMessage: errorMessage,
    );
  }
}
