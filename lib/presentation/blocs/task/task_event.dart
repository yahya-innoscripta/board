import 'package:equatable/equatable.dart';
import '../../../domain/entities/task.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class CreateTask extends TaskEvent {
  final String title;
  final String description;

  CreateTask({required this.title, required this.description});

  @override
  List<Object?> get props => [title, description];
}

class UpdateTaskStatus extends TaskEvent {
  final Task task;
  final TaskStatus newStatus;

  UpdateTaskStatus({required this.task, required this.newStatus});

  @override
  List<Object?> get props => [task, newStatus];
}

class DeleteTask extends TaskEvent {
  final String taskId;

  DeleteTask({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

class UpdateTask extends TaskEvent {
  final Task task;

  UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class LoadCompletedTasks extends TaskEvent {}
