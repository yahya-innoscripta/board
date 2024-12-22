import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innoscripta/domain/entities/comment.dart';
import '../../../domain/repositories/comment_repository.dart';
import 'comment_event.dart';
import 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final CommentRepository commentRepository;

  CommentBloc({required this.commentRepository}) : super(CommentInitial()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<DeleteComment>(_onDeleteComment);
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<CommentState> emit,
  ) async {
    emit(CommentLoading());
    try {
      final comments = await commentRepository.getCommentsForTask(event.taskId);
      emit(CommentsLoaded(comments));
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }

  Future<void> _onAddComment(
      AddComment event, Emitter<CommentState> emit) async {
    if (state is CommentsLoaded) {
      final currentState = state as CommentsLoaded;
      final currentComments = List<Comment>.from(currentState.comments);

      emit(CommentsLoaded(
        currentComments,
        pendingComment: event.comment,
        currentComments: currentComments,
      ));

      try {
        final newComment = await commentRepository.addComment(event.comment);
        final updatedComments = [newComment, ...currentComments];
        emit(CommentsLoaded(updatedComments));
      } catch (e) {
        emit(CommentsLoaded(currentComments));
        emit(CommentError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteComment(
      DeleteComment event, Emitter<CommentState> emit) async {
    try {
      await commentRepository.deleteComment(event.commentId);
      final comments = await commentRepository.getCommentsForTask(event.taskId);
      emit(CommentsLoaded(comments));
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }
}
