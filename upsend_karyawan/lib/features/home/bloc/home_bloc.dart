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
      emit(state.copyWith(
        status: HomeStatus.loaded,
        todayAttendance: attendance,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onCheckOutRequested(
    HomeCheckOutRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.todayAttendance == null) return;

    emit(state.copyWith(status: HomeStatus.submitting));
    try {
      // Backend WAJIB terima lat/lng saat check-out (lihat AttendanceController@checkOut),
      // jadi ambil posisi device saat ini dulu sebelum manggil repository.
      // NOTE: ini asumsi permission lokasi udah granted dari flow check-in
      // sebelumnya. Kalau user belum pernah kasih izin lokasi sama sekali,
      // getCurrentPosition() bisa throw — perlu handling permission
      // terpisah kalau itu skenario yang mungkin terjadi di app kamu.
      final position = await Geolocator.getCurrentPosition();

      await _homeRepository.checkOut(
        attendanceId: state.todayAttendance!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      // Setelah checkout sukses, otomatis gak ada "open session" lagi
      // (backend definisinya whereNull('check_out_time')) — makanya
      // di-clear ke null, bukan disimpan hasil updatenya. AttendanceModel
      // yang kamu kasih juga gak punya field checkOutTime, jadi gak ada
      // cara lain buat tau statusnya selain via clear ini.
      emit(state.copyWith(
        status: HomeStatus.loaded,
        clearAttendance: true,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()));
    }
  }
}