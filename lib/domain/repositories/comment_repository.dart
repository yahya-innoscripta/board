import '../entities/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getCommentsForTask(String taskId);
  Future<Comment> addComment(Comment comment);
  Future<void> deleteComment(String id);
}
