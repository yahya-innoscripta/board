import 'package:innoscripta/domain/entities/comment.dart';

enum TaskStatus {
  todo,
  inProgress,
  done,
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<Comment> comments;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    List<Comment>? comments,
  }) : comments = comments ?? [];

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? completedAt,
    List<Comment>? comments,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      comments: comments ?? this.comments,
    );
  }
}
