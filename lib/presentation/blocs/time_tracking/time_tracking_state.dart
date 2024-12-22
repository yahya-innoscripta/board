import 'package:equatable/equatable.dart';
import 'package:innoscripta/domain/entities/time_entry.dart';

abstract class TimeTrackingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TimeTrackingInitial extends TimeTrackingState {}

class TimeTrackingLoading extends TimeTrackingState {}

class TimeTrackingLoaded extends TimeTrackingState {
  final TimeEntry? currentTimer;
  final List<TimeEntry> timeEntries;
  final Duration totalDuration;

  TimeTrackingLoaded({
    this.currentTimer,
    required this.timeEntries,
    required this.totalDuration,
  });

  @override
  List<Object?> get props => [currentTimer, timeEntries, totalDuration];
}

class TimeTrackingError extends TimeTrackingState {
  final String message;

  TimeTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
