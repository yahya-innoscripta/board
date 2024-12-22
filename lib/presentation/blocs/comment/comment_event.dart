import 'package:equatable/equatable.dart';
import '../../../domain/entities/comment.dart';

abstract class CommentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadComments extends CommentEvent {
  final String taskId;

  LoadComments(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class AddComment extends CommentEvent {
  final Comment comment;

  AddComment(this.comment);

  @override
  List<Object?> get props => [comment];
}

class DeleteComment extends CommentEvent {
  final String commentId;
  final String taskId;

  DeleteComment({required this.commentId, required this.taskId});

  @override
  List<Object?> get props => [commentId, taskId];
}
