import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../repository/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;

  HomeBloc({required HomeRepository homeRepository})
    : _homeRepository = homeRepository,
      super(HomeState.initial()) {
    on<HomeStarted>(_onStarted);
    on<HomeCheckOutRequested>(_onCheckOutRequested);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final attendance = await _homeRepository.getTodayAttendance();
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          todayAttendance: attendance,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onCheckOutRequested(
    HomeCheckOutRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.todayAttendance == null) return;
    if (state.status == HomeStatus.submitting) return;

    emit(state.copyWith(status: HomeStatus.submitting));
    try {
      // Cek GPS aktif dulu, sama seperti flow Check In
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif, mohon nyalakan lokasi.');
      }

      // Cek & minta permission dulu, sama seperti flow Check In
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

      await _homeRepository.checkOut(
        attendanceId: state.todayAttendance!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          clearAttendance: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
