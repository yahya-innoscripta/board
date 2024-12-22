import 'package:dio/dio.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';

class TodoistCommentRepository implements CommentRepository {
  final String _baseUrl = 'https://api.todoist.com/rest/v2';
  final String _token;
  late final Dio _dio;

  TodoistCommentRepository({required String token}) : _token = token {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $_token',
      },
    ));
  }

  @override
  Future<List<Comment>> getCommentsForTask(String taskId) async {
    try {
      final response =
          await _dio.get('/comments', queryParameters: {'task_id': taskId});

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => _mapToComment(json)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load comments: ${e.message}');
    }
  }

  @override
  Future<Comment> addComment(Comment comment) async {
    try {
      final response = await _dio.post(
        '/comments',
        data: {
          'task_id': comment.taskId,
          'content': comment.content,
        },
      );

      if (response.statusCode == 200) {
        return _mapToComment(response.data);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to add comment: ${e.message}');
    }
  }

  @override
  Future<void> deleteComment(String id) async {
    try {
      final response = await _dio.delete('/comments/$id');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to delete comment: ${e.message}');
    }
  }

  Comment _mapToComment(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      taskId: json['task_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['posted_at']),
    );
  }
}
