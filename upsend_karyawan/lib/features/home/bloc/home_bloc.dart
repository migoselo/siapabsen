import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../attendance/models/attendance_model.dart';
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
      final results = await Future.wait([
        _homeRepository.getTodayAttendance(),
        _homeRepository.getHistory(),
      ]);
      final attendance = results[0] as AttendanceModel?;
      final history = results[1] as List<AttendanceModel>;

      final todayAttendance = _resolveTodayAttendance(attendance, history);

      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          todayAttendance: todayAttendance,
          history: history,
          errorMessage: null,
          clearAttendance: todayAttendance == null,
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

    emit(state.copyWith(status: HomeStatus.submitting));
    try {
      final position = await Geolocator.getCurrentPosition();

      await _homeRepository.checkOut(
        attendanceId: state.todayAttendance!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      final results = await Future.wait([
        _homeRepository.getTodayAttendance(),
        _homeRepository.getHistory(),
      ]);
      final attendance = results[0] as AttendanceModel?;
      final history = results[1] as List<AttendanceModel>;

      final todayAttendance = _resolveTodayAttendance(attendance, history);

      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          todayAttendance: todayAttendance,
          history: history,
          errorMessage: null,
          clearAttendance: todayAttendance == null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  AttendanceModel? _resolveTodayAttendance(
    AttendanceModel? attendance,
    List<AttendanceModel> history,
  ) {
    if (attendance != null && attendance.checkOutTime == null)
      return attendance;

    final now = DateTime.now();
    final openSessions = history.where((item) {
      final checkIn = item.checkInTime.toLocal();
      return item.checkOutTime == null &&
          checkIn.year == now.year &&
          checkIn.month == now.month &&
          checkIn.day == now.day;
    });
    return openSessions.isNotEmpty ? openSessions.first : null;
  }
}
