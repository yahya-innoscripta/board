import 'package:dio/dio.dart';
import 'package:innoscripta/infrastructure/exceptions/repository_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:async';

class TodoistTaskRepository implements TaskRepository {
  final Dio _dio;
  final Dio _syncDio;
  // Section names that map to our task states
  static const String _todoSection = 'Todo';
  static const String _inProgressSection = 'In Progress';
  static const String _doneSection = 'Done';

  // Cache section IDs after creation
  String? _todoSectionId;
  String? _inProgressSectionId;
  String? _doneSectionId;
  String? _projectId;

  final _uuid = const Uuid();

  // Add initialization tracking
  late final Completer<void> _initializationCompleter;
  bool _isInitialized = false;

  TodoistTaskRepository({
    required String apiToken,
    required Dio restDio,
    required Dio syncDio,
  })  : _dio = restDio,
        _syncDio = syncDio {
    _initializationCompleter = Completer<void>();
    // Initialize sections immediately
    _initializeSections();
  }

  // Add this method to ensure initialization is complete
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializationCompleter.future;
    }
  }

  Future<void> _initializeSections() async {
    try {
      // First get or create the main project
      final projects = await _dio.get('/projects');
      final projectsList = projects.data as List;

      // Use the first project or create a new one
      if (projectsList.isEmpty) {
        final createProjectResponse = await _dio.post(
          '/projects',
          data: {'name': 'Task Board', 'color': 'berry_red'},
        );
        _projectId = createProjectResponse.data['id'];
      } else {
        _projectId = projectsList[0]['id'];
      }

      // Get existing sections
      final sections = await _dio.get(
        '/sections',
        queryParameters: {'project_id': _projectId},
      );
      final sectionsList = sections.data as List;

      // Find or create each section
      for (final sectionData in sectionsList) {
        switch (sectionData['name']) {
          case _todoSection:
            _todoSectionId = sectionData['id'];
            break;
          case _inProgressSection:
            _inProgressSectionId = sectionData['id'];
            break;
          case _doneSection:
            _doneSectionId = sectionData['id'];
            break;
        }
      }

      // Create any missing sections
      if (_todoSectionId == null) {
        final response = await _dio.post(
          '/sections',
          data: {'project_id': _projectId, 'name': _todoSection},
        );
        _todoSectionId = response.data['id'];
      }

      if (_inProgressSectionId == null) {
        final response = await _dio.post(
          '/sections',
          data: {'project_id': _projectId, 'name': _inProgressSection},
        );
        _inProgressSectionId = response.data['id'];
      }

      if (_doneSectionId == null) {
        final response = await _dio.post(
          '/sections',
          data: {'project_id': _projectId, 'name': _doneSection},
        );
        _doneSectionId = response.data['id'];
      }

      // Mark as initialized and complete the completer
      _isInitialized = true;
      _initializationCompleter.complete();
    } catch (e) {
      print('Error initializing sections: $e');
      _initializationCompleter.completeError(e);
      rethrow;
    }
  }

  String _getSectionIdForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return _todoSectionId!;
      case TaskStatus.inProgress:
        return _inProgressSectionId!;
      case TaskStatus.done:
        return _doneSectionId!;
    }
  }

  TaskStatus _getStatusFromSectionId(String? sectionId) {
    if (sectionId == _inProgressSectionId) {
      return TaskStatus.inProgress;
    } else if (sectionId == _doneSectionId) {
      return TaskStatus.done;
    }
    return TaskStatus.todo;
  }

  @override
  Future<List<Task>> getAllTasks() async {
    await _ensureInitialized();
    try {
      final response = await _dio.get(
        '/tasks',
        queryParameters: {'project_id': _projectId},
      );
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => _mapJsonToTask(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    await _ensureInitialized();
    try {
      final response = await _dio.post(
        '/tasks',
        data: {
          'content': task.title,
          'description': task.description,
          'project_id': _projectId,
          'section_id': _getSectionIdForStatus(task.status),
          'due_string': 'today', // Default due date
          'priority': 1, // Default priority (1-4, 4 is highest)
          'label_ids': [], // Can be used for tags/categories
        },
      );

      return _mapJsonToTask(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    await _ensureInitialized();
    try {
      final currentTask = await getTaskById(task.id);

      // If status has changed, use sync API to move the task
      if (currentTask.status != task.status) {
        final moveCommand = {
          'type': 'item_move',
          'uuid': _uuid.v4(),
          'args': {
            'id': task.id,
            'section_id': _getSectionIdForStatus(task.status)
          }
        };

        await _syncDio.post(
          '/sync',
          data: {
            'commands': jsonEncode([moveCommand])
          },
        );
      }

      // Update other task properties using REST API
      await _dio.post(
        '/tasks/${task.id}',
        data: {
          'content': task.title,
          'description': task.description,
        },
      );

      // Get the latest task state using REST API
      final updatedResponse = await _dio.get('/tasks/${task.id}');
      return _mapJsonToTask(updatedResponse.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    await _ensureInitialized();
    try {
      final sectionId = _getSectionIdForStatus(status);
      final response = await _dio.get(
        '/tasks',
        queryParameters: {'section_id': sectionId},
      );
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => _mapJsonToTask(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Task _mapJsonToTask(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['content'],
      description: json['description'] ?? '',
      status: _getStatusFromSectionId(json['section_id']),
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      comments: [],
    );
  }

  @override
  Future<Task> getTaskById(String id) async {
    await _ensureInitialized();
    try {
      final response = await _dio.get('/tasks/$id');
      return _mapJsonToTask(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await _ensureInitialized();
    try {
      await _dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    await _ensureInitialized();
    try {
      final response = await _dio.get(
        '/tasks',
        queryParameters: {
          'project_id': _projectId,
          'section_id': _doneSectionId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => _mapJsonToTask(json)).toList();
      } else {
        throw RepositoryException(
            'Failed to load completed tasks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RepositoryException(
            'Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        if (responseData != null && responseData is Map<String, dynamic>) {
          final syncStatus = responseData['sync_status'];
          if (syncStatus != null) {
            return RepositoryException('Sync API Error: $syncStatus');
          }
        }
        return RepositoryException(
            'API Error $statusCode: ${e.response?.data}');
      case DioExceptionType.cancel:
        return RepositoryException('Request cancelled');
      default:
        return RepositoryException('Network error occurred: ${e.message}');
    }
  }
}
