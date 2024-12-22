import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../exceptions/repository_exception.dart';

class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};
  final _uuid = const Uuid();

  @override
  Future<List<Task>> getAllTasks() async {
    return _tasks.values.toList();
  }

  @override
  Future<Task> getTaskById(String id) async {
    final task = _tasks[id];
    if (task == null) {
      throw RepositoryException('Task not found with id: $id');
    }
    return task;
  }

  @override
  Future<Task> createTask(Task task) async {
    final newTask = Task(
      id: _uuid.v4(),
      title: task.title,
      description: task.description,
      status: task.status,
      createdAt: DateTime.now(),
      comments: task.comments,
    );
    _tasks[newTask.id] = newTask;
    return newTask;
  }

  @override
  Future<Task> updateTask(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw RepositoryException('Task not found with id: ${task.id}');
    }
    _tasks[task.id] = task;
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (!_tasks.containsKey(id)) {
      throw RepositoryException('Task not found with id: $id');
    }
    _tasks.remove(id);
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    return _tasks.values.where((task) => task.status == status).toList();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    return _tasks.values
        .where((task) => task.status == TaskStatus.done)
        .toList();
  }
}
