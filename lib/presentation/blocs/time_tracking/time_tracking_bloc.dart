import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innoscripta/domain/repositories/time_entry_repository.dart';
import 'package:innoscripta/presentation/blocs/time_tracking/time_tracking_event.dart';
import 'package:innoscripta/presentation/blocs/time_tracking/time_tracking_state.dart';

class TimeTrackingBloc extends Bloc<TimeTrackingEvent, TimeTrackingState> {
  final TimeEntryRepository timeEntryRepository;

  TimeTrackingBloc({required this.timeEntryRepository})
      : super(TimeTrackingInitial()) {
    on<LoadTimeTracking>(_onLoadTimeTracking);
    on<StartTimer>(_onStartTimer);
    on<StopTimer>(_onStopTimer);
  }

  Future<void> _onLoadTimeTracking(
    LoadTimeTracking event,
    Emitter<TimeTrackingState> emit,
  ) async {
    emit(TimeTrackingLoading());
    try {
      final currentTimer =
          await timeEntryRepository.getCurrentRunningTimer(event.taskId);
      final timeEntries =
          await timeEntryRepository.getTimeEntriesForTask(event.taskId);
      final totalDuration =
          await timeEntryRepository.getTotalDurationForTask(event.taskId);

      emit(TimeTrackingLoaded(
        currentTimer: currentTimer,
        timeEntries: timeEntries,
        totalDuration: totalDuration,
      ));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onStartTimer(
    StartTimer event,
    Emitter<TimeTrackingState> emit,
  ) async {
    try {
      await timeEntryRepository.startTimer(event.taskId);
      add(LoadTimeTracking(event.taskId));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onStopTimer(
    StopTimer event,
    Emitter<TimeTrackingState> emit,
  ) async {
    try {
      await timeEntryRepository.stopTimer(event.timeEntryId);
      if (state is TimeTrackingLoaded) {
        final currentState = state as TimeTrackingLoaded;
        add(LoadTimeTracking(currentState.currentTimer!.taskId));
      }
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<Duration> getTaskDuration(String taskId) async {
    try {
      return await timeEntryRepository.getTotalDurationForTask(taskId);
    } catch (e) {
      return Duration.zero;
    }
  }
}
