import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;

  AttendanceBloc({required this.repository}) : super(AttendanceState()) {
    on<FetchNearbyLocations>(_onFetchNearbyLocations);
    on<SelectLocation>(_onSelectLocation);
    on<PhotoCaptured>(_onPhotoCaptured);
    on<GoToCamera>(_onGoToCamera);
    on<SubmitCheckIn>(_onSubmitCheckIn);
    on<PreviousStep>(_onPreviousStep);
    on<ResetAttendance>(_onResetAttendance);
  }

  Future<void> _onFetchNearbyLocations(
    FetchNearbyLocations event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStatus.loading));
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

      final locations = await repository.getNearbyLocations(
        lat: position.latitude,
        lng: position.longitude,
      );

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          nearbyLocations: locations,
          selectedLocation: locations.isNotEmpty ? locations.first : null,
          clearSelectedLocation: locations.isEmpty,
          latitude: position.latitude,
          longitude: position.longitude,
          currentStep: 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.failure,
          errorMessage: e.toString(),
          clearSelectedLocation: true,
        ),
      );
    }
  }

  void _onGoToCamera(GoToCamera event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(currentStep: 2));
  }

  void _onSelectLocation(SelectLocation event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(selectedLocation: event.location));
  }

  void _onPhotoCaptured(PhotoCaptured event, Emitter<AttendanceState> emit) {
    emit(
      state.copyWith(
        capturedPhoto: event.photo,
        currentStep: 2,
        status: AttendanceStatus.success,
      ),
    );
  }

  Future<void> _onSubmitCheckIn(
    SubmitCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.selectedLocation == null || state.capturedPhoto == null) return;

    emit(state.copyWith(status: AttendanceStatus.loading));
    try {
      final result = await repository.checkIn(
        locationId: state.selectedLocation!.id,
        lat: state.latitude!,
        lng: state.longitude!,
        photo: state.capturedPhoto!,
      );

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          attendanceResult: result,
          currentStep: 3,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onPreviousStep(PreviousStep event, Emitter<AttendanceState> emit) {
    if (state.currentStep == 2) {
      emit(state.copyWith(currentStep: 1));
    }
  }

  void _onResetAttendance(
    ResetAttendance event,
    Emitter<AttendanceState> emit,
  ) {
    emit(AttendanceState());
  }
}
