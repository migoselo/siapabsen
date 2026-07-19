import 'package:equatable/equatable.dart';
import '../../attendance/models/attendance_model.dart'; // sesuaikan path import ke lokasi model temen kamu

enum HomeStatus { initial, loading, loaded, submitting, failure }

class HomeState extends Equatable {
  final HomeStatus status;

  // Data attendance hari ini — null berarti belum check-in.
  // Diisi dari AttendanceRepository.getTodayAttendance() (method baru,
  // lihat catatan di attendance_repository.dart — belum dikonfirmasi backend).
  final AttendanceModel? todayAttendance;

  final String? errorMessage;

  const HomeState({
    required this.status,
    required this.todayAttendance,
    this.errorMessage,
  });

  factory HomeState.initial() => const HomeState(
        status: HomeStatus.initial,
        todayAttendance: null,
      );

  // Getter turunan — dipakai langsung di UI, jadi UI gak perlu tau detail model.
  bool get isCheckedIn => todayAttendance != null;
  String? get locationName => todayAttendance?.location?.name;
  DateTime? get checkInTime => todayAttendance?.checkInTime;

  HomeState copyWith({
    HomeStatus? status,
    AttendanceModel? todayAttendance,
    bool clearAttendance = false, // dipakai setelah checkout sukses
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      todayAttendance: clearAttendance ? null : (todayAttendance ?? this.todayAttendance),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, todayAttendance, errorMessage];
}