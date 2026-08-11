import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository repository;

  HistoryBloc({required this.repository}) : super(const HistoryState()) {
    on<HistoryFetchRequested>(_onFetchRequested);
  }

  Future<void> _onFetchRequested(
    HistoryFetchRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final records = await repository.getHistory(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(state.copyWith(status: HistoryStatus.loaded, records: records));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}