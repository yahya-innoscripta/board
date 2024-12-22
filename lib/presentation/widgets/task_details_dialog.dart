import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innoscripta/domain/entities/task.dart';
import 'package:innoscripta/domain/repositories/comment_repository.dart';
import 'package:innoscripta/domain/repositories/time_entry_repository.dart';
import 'package:innoscripta/presentation/blocs/task/task_bloc.dart';
import 'package:innoscripta/presentation/blocs/task/task_event.dart';
import 'package:innoscripta/presentation/blocs/task/task_state.dart';
import 'comment_section.dart';
import 'time_tracking_section.dart';

class TaskDetailsDialog extends StatefulWidget {
  final Task task;
  final CommentRepository commentRepository;
  final TimeEntryRepository timeEntryRepository;

  const TaskDetailsDialog({
    super.key,
    required this.task,
    required this.commentRepository,
    required this.timeEntryRepository,
  });

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: _currentTask.title);
    _descriptionController =
        TextEditingController(text: _currentTask.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TasksLoaded) {
          final updatedTask = state.tasks.firstWhere(
            (task) => task.id == _currentTask.id,
            orElse: () => _currentTask,
          );
          if (updatedTask != _currentTask) {
            setState(() {
              _currentTask = updatedTask;
              if (!_isEditing) {
                _initializeControllers();
              }
            });
          }
        }
      },
      child: Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? size.width * 0.95 : size.width * 0.8,
            maxHeight: size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: isSmallScreen
                    ? _buildVerticalLayout()
                    : _buildHorizontalLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _titleController,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      )
                    : Text(
                        _currentTask.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit task',
                ),
              if (_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveChanges,
                  tooltip: 'Save changes',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _isEditing = false),
                  tooltip: 'Cancel editing',
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
            ],
          ),
          if (_currentTask.description.isNotEmpty || _isEditing) ...[
            const SizedBox(height: 16),
            _isEditing
                ? TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add description...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  )
                : Text(
                    _currentTask.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  void _saveChanges() {
    final updatedTask = _currentTask.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
    );

    context.read<TaskBloc>().add(UpdateTask(updatedTask));
    setState(() => _isEditing = false);
  }

  Widget _buildVerticalLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimeTrackingSection(taskId: _currentTask.id),
          const SizedBox(height: 32),
          CommentSection(taskId: _currentTask.id),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TimeTrackingSection(taskId: _currentTask.id),
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 24),
          color: Colors.grey.withOpacity(0.2),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: CommentSection(taskId: _currentTask.id),
          ),
        ),
      ],
    );
  }
}
