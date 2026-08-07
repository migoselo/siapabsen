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
      // Ambil status hari ini & history bareng-bareng
      final results = await Future.wait([
        _homeRepository.getTodayAttendance(),
        _homeRepository.getHistory(),
      ]);
      final attendance = results[0] as dynamic;
      final history = results[1] as List;

      emit(state.copyWith(
        status: HomeStatus.loaded,
        todayAttendance: attendance,
        history: history.cast(),
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
      final position = await Geolocator.getCurrentPosition();

      await _homeRepository.checkOut(
        attendanceId: state.todayAttendance!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      // Refresh history juga biar entry check-out baru langsung muncul
      final history = await _homeRepository.getHistory();

      emit(state.copyWith(
        status: HomeStatus.loaded,
        clearAttendance: true,
        history: history,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()));
    }
  }
}