import 'package:equatable/equatable.dart';
import '../../attendance/models/attendance_model.dart';

enum HomeStatus { initial, loading, loaded, submitting, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final AttendanceModel? todayAttendance;
  final List<AttendanceModel> history; // BARU — buat Presensi Terakhir
  final String? errorMessage;

  const HomeState({
    required this.status,
    required this.todayAttendance,
    required this.history,
    this.errorMessage,
  });

  factory HomeState.initial() => const HomeState(
    status: HomeStatus.initial,
    todayAttendance: null,
    history: [],
  );

  bool get isCheckedIn =>
      todayAttendance != null && todayAttendance!.checkOutTime == null;
  String? get locationName =>
      isCheckedIn ? todayAttendance?.location?.name : null;
  DateTime? get checkInTime =>
      isCheckedIn ? todayAttendance?.checkInTime : null;

  DateTime? get checkOutTime => todayAttendance?.checkOutTime;

  HomeState copyWith({
    HomeStatus? status,
    AttendanceModel? todayAttendance,
    List<AttendanceModel>? history,
    bool clearAttendance = false,
    String? errorMessage,
  }) {
    final resolvedTodayAttendance = clearAttendance
        ? null
        : (todayAttendance ?? this.todayAttendance);

    return HomeState(
      status: status ?? this.status,
      todayAttendance: resolvedTodayAttendance,
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, todayAttendance, history, errorMessage];
}
