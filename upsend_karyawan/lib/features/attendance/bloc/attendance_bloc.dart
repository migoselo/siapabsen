import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;

  AttendanceBloc({required this.repository}) : super(AttendanceState()) {
    on<FetchNearbyLocations>(_onFetchNearbyLocations);
    on<SelectLocation>(_onSelectLocation);
    on<PhotoCaptured>(_onPhotoCaptured);
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
      // Mock Koordinat Asli (Ganti dengan LocationService bawaan jika sudah siap)
      double currentLat = -7.5841;
      double currentLng = 112.0628;

      final locations = await repository.getNearbyLocations(
        lat: currentLat,
        lng: currentLng,
      );

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          nearbyLocations: locations,
          selectedLocation: locations.isNotEmpty ? locations.first : null,
          latitude: currentLat,
          longitude: currentLng,
          currentStep: 1,
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

  void _onSelectLocation(SelectLocation event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(selectedLocation: event.location));
  }

  void _onPhotoCaptured(PhotoCaptured event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(capturedPhoto: event.photo, currentStep: 2));
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
