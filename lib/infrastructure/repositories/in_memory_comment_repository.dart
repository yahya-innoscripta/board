import 'package:uuid/uuid.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../exceptions/repository_exception.dart';

class InMemoryCommentRepository implements CommentRepository {
  final Map<String, Comment> _comments = {};
  final _uuid = const Uuid();

  @override
  Future<List<Comment>> getCommentsForTask(String taskId) async {
    return _comments.values
        .where((comment) => comment.taskId == taskId)
        .toList();
  }

  @override
  Future<Comment> addComment(Comment comment) async {
    final newComment = Comment(
      id: _uuid.v4(),
      taskId: comment.taskId,
      content: comment.content,
      createdAt: DateTime.now(),
    );
    _comments[newComment.id] = newComment;
    return newComment;
  }

  @override
  Future<void> deleteComment(String id) async {
    if (!_comments.containsKey(id)) {
      throw RepositoryException('Comment not found with id: $id');
    }
    _comments.remove(id);
  }
}
