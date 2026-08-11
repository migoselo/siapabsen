import 'package:equatable/equatable.dart';
import '../../attendance/models/attendance_model.dart';

enum HistoryStatus { initial, loading, loaded, failure }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<AttendanceModel> records;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<AttendanceModel>? records,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, errorMessage];
}