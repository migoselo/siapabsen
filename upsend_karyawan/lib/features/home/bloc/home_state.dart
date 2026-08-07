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

  bool get isCheckedIn => todayAttendance?.checkInTime != null;
  String? get locationName => todayAttendance?.location?.name;
  DateTime? get checkInTime => todayAttendance?.checkInTime;

  HomeState copyWith({
    HomeStatus? status,
    AttendanceModel? todayAttendance,
    List<AttendanceModel>? history,
    bool clearAttendance = false,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      todayAttendance: clearAttendance ? null : (todayAttendance ?? this.todayAttendance),
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, todayAttendance, history, errorMessage];
}