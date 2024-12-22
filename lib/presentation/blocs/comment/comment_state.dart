import 'package:equatable/equatable.dart';
import '../../../domain/entities/comment.dart';

abstract class CommentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CommentInitial extends CommentState {}

class CommentLoading extends CommentState {}

class CommentsLoaded extends CommentState {
  final List<Comment> comments;
  final Comment? pendingComment;
  final List<Comment>? currentComments;

  CommentsLoaded(
    this.comments, {
    this.pendingComment,
    this.currentComments,
  });

  @override
  List<Object?> get props => [comments, pendingComment, currentComments];
}

class CommentError extends CommentState {
  final String message;

  CommentError(this.message);

  @override
  List<Object?> get props => [message];
}

class CommentSubmitting extends CommentState {
  final List<Comment> currentComments;
  final Comment pendingComment;

  CommentSubmitting(this.currentComments, this.pendingComment);

  @override
  List<Object?> get props => [currentComments, pendingComment];
}
