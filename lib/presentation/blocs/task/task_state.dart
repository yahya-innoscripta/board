import 'package:equatable/equatable.dart';
import '../../../domain/entities/task.dart';

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TasksLoaded extends TaskState {
  final List<Task> tasks;
  final String? backgroundMessage;
  final bool isError;
  final Set<String> updatingTaskIds;

  TasksLoaded(
    this.tasks, {
    this.backgroundMessage,
    this.isError = false,
    this.updatingTaskIds = const {},
  });

  @override
  List<Object?> get props =>
      [tasks, backgroundMessage, isError, updatingTaskIds];

  TasksLoaded copyWith({
    List<Task>? tasks,
    String? backgroundMessage,
    bool? isError,
    Set<String>? updatingTaskIds,
  }) {
    return TasksLoaded(
      tasks ?? this.tasks,
      backgroundMessage: backgroundMessage,
      isError: isError ?? this.isError,
      updatingTaskIds: updatingTaskIds ?? this.updatingTaskIds,
    );
  }

  // Helper method to get tasks by status while maintaining order
  List<Task> getTasksByStatus(TaskStatus status) {
    return tasks.where((task) => task.status == status).toList();
  }
}

class TaskError extends TaskState {
  final String message;

  TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
