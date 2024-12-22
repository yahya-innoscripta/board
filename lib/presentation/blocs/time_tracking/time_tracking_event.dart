import 'package:equatable/equatable.dart';

abstract class TimeTrackingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTimeTracking extends TimeTrackingEvent {
  final String taskId;

  LoadTimeTracking(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class StartTimer extends TimeTrackingEvent {
  final String taskId;

  StartTimer(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class StopTimer extends TimeTrackingEvent {
  final String timeEntryId;

  StopTimer(this.timeEntryId);

  @override
  List<Object?> get props => [timeEntryId];
}
