import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/entities/task.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc({required this.taskRepository}) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTaskStatus>(_onUpdateTaskStatus);
    on<DeleteTask>(_onDeleteTask);
    on<UpdateTask>(_onUpdateTask);
    on<LoadCompletedTasks>(_onLoadCompletedTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getAllTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.createTask(
        Task(
          id: '', // Will be generated by repository
          title: event.title,
          description: event.description,
          status: TaskStatus.todo,
          createdAt: DateTime.now(),
        ),
      );
      final tasks = await taskRepository.getAllTasks();
      emit(TasksLoaded(tasks, backgroundMessage: 'Task created successfully'));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTaskStatus(
      UpdateTaskStatus event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;

      // Check if task is already being updated
      if (currentState.updatingTaskIds.contains(event.task.id)) {
        return; // Skip if task is already being updated
      }

      // Create new sets and lists to avoid mutation issues
      final updatingTaskIds = Set<String>.from(currentState.updatingTaskIds)
        ..add(event.task.id);
      final oldTasks = List<Task>.from(currentState.tasks);

      // Find task's current index for proper reordering
      final taskIndex = oldTasks.indexWhere((t) => t.id == event.task.id);
      if (taskIndex == -1) return; // Task not found

      // Create updated task
      final updatedTask = event.task.copyWith(
        status: event.newStatus,
        completedAt: event.newStatus == TaskStatus.done ? DateTime.now() : null,
      );

      // Create new list with updated task
      final updatedTasks = List<Task>.from(oldTasks)
        ..removeAt(taskIndex)
        ..insert(taskIndex, updatedTask);

      // Emit optimistic update
      emit(currentState.copyWith(
        tasks: updatedTasks,
        updatingTaskIds: updatingTaskIds,
      ));

      try {
        // Perform the actual update
        final serverUpdatedTask = await taskRepository.updateTask(updatedTask);

        // Get the latest state after the async operation
        final latestState = state as TasksLoaded;
        final latestTasks = List<Task>.from(latestState.tasks);

        // Find the task's current position in the latest state
        final currentIndex =
            latestTasks.indexWhere((t) => t.id == event.task.id);
        if (currentIndex != -1) {
          // Update the task with server response while maintaining order
          latestTasks
            ..removeAt(currentIndex)
            ..insert(currentIndex, serverUpdatedTask);
        }

        // Remove task from updating set and show success
        emit(latestState.copyWith(
          tasks: latestTasks,
          backgroundMessage: 'Task status updated successfully',
          updatingTaskIds: Set<String>.from(latestState.updatingTaskIds)
            ..remove(event.task.id),
        ));
      } catch (e) {
        // Get the latest state for proper error handling
        final latestState = state as TasksLoaded;

        // Find the task in the latest state
        final revertedTasks = List<Task>.from(latestState.tasks);
        final currentIndex =
            revertedTasks.indexWhere((t) => t.id == event.task.id);

        if (currentIndex != -1) {
          // Revert the specific task while maintaining other tasks' states
          revertedTasks
            ..removeAt(currentIndex)
            ..insert(currentIndex, event.task);
        }

        // Emit error state while maintaining other updating tasks
        emit(latestState.copyWith(
          tasks: revertedTasks,
          backgroundMessage: 'Failed to update task status',
          isError: true,
          updatingTaskIds: Set<String>.from(latestState.updatingTaskIds)
            ..remove(event.task.id),
        ));
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final oldTasks = List<Task>.from(currentState.tasks);

      // Optimistically remove the task from UI
      final updatedTasks =
          oldTasks.where((task) => task.id != event.taskId).toList();
      emit(TasksLoaded(updatedTasks));

      try {
        await taskRepository.deleteTask(event.taskId);
        emit(TasksLoaded(
          updatedTasks,
          backgroundMessage: 'Task deleted successfully',
        ));
      } catch (e) {
        // Revert if there's an error
        emit(TasksLoaded(
          oldTasks,
          backgroundMessage: 'Failed to delete task',
          isError: true,
        ));
      }
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final oldTasks = List<Task>.from(currentState.tasks);

      // Optimistically update the task in UI
      final updatedTasks = oldTasks.map((task) {
        if (task.id == event.task.id) {
          return event.task;
        }
        return task;
      }).toList();

      emit(TasksLoaded(updatedTasks));

      try {
        await taskRepository.updateTask(event.task);
        emit(TasksLoaded(
          updatedTasks,
          backgroundMessage: 'Task updated successfully',
        ));
      } catch (e) {
        // Revert if there's an error
        emit(TasksLoaded(
          oldTasks,
          backgroundMessage: 'Failed to update task',
          isError: true,
        ));
      }
    }
  }

  Future<void> _onLoadCompletedTasks(
    LoadCompletedTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getCompletedTasks();
      emit(TasksLoaded(tasks));
    } catch (e, stackTrace) {
      print(e.toString());
      print(stackTrace);
      emit(TaskError(e.toString()));
    }
  }
}
