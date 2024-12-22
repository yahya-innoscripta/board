import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:innoscripta/domain/repositories/time_entry_repository.dart';
import 'package:innoscripta/presentation/blocs/comment/comment_bloc.dart';
import 'package:innoscripta/presentation/blocs/task/task_state.dart';
import 'package:innoscripta/presentation/blocs/time_tracking/time_tracking_bloc.dart';
import '../../domain/entities/task.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';
import 'task_card.dart';
import 'task_details_dialog.dart';
import '../../infrastructure/di/service_locator.dart';

class TaskBoard extends StatefulWidget {
  final List<Task> tasks;

  const TaskBoard({
    super.key,
    required this.tasks,
  });

  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  static const double _scrollThreshold =
      100.0; // Pixels from edge to trigger scroll
  static const double _scrollSpeed = 5.0; // Pixels per frame

  @override
  void initState() {
    super.initState();
    // Ensure scroll controller is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(() {
          // Add any scroll listeners if needed
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel timer and dispose scroll controller
    _scrollTimer?.cancel();
    _scrollController.removeListener(() {});
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (!mounted || !_scrollController.hasClients) return;

    final containerWidth = context.size?.width ?? 0;
    final dx = details.globalPosition.dx;

    // Cancel existing timer
    _scrollTimer?.cancel();

    if (dx < _scrollThreshold) {
      _startScrolling(-_scrollSpeed);
    } else if (dx > containerWidth - _scrollThreshold) {
      _startScrolling(_scrollSpeed);
    } else {
      _stopScrolling();
    }
  }

  void _startScrolling(double speed) {
    // Cancel any existing timer first
    _stopScrolling();

    if (!mounted) return;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }

      final newOffset = _scrollController.offset + speed;
      if (newOffset < 0 ||
          newOffset > _scrollController.position.maxScrollExtent) {
        timer.cancel();
        return;
      }

      _scrollController.jumpTo(newOffset);
    });
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  @override
  void didUpdateWidget(TaskBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle any necessary updates when widget is rebuilt
    if (!mounted) {
      _stopScrolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TimeTrackingBloc>(),
      child: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TasksLoaded && state.backgroundMessage != null) {
            CherryToast(
              icon: state.isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              themeColor: state.isError
                  ? const Color(0xFFE44D42)
                  : const Color(0xFF2BC48A),
              title: Text(
                state.backgroundMessage!,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              toastPosition: Position.bottom,
              animationType: AnimationType.fromBottom,
              autoDismiss: true,
              animationDuration: const Duration(milliseconds: 200),
              toastDuration: const Duration(seconds: 3),
              action: state.isError
                  ? const Text(
                      'Retry',
                      style: TextStyle(
                        color: Color(0xFFE44D42),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
              actionHandler: state.isError
                  ? () => context.read<TaskBloc>().add(LoadTasks())
                  : null,
            ).show(context);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            const minColumnWidth = 300.0; // Minimum width for each column
            const padding = 32.0; // Total horizontal padding
            const columnSpacing = 16.0; // Space between columns
            const columnCount = 3; // Number of columns
            const totalSpacing =
                padding + (columnSpacing * (columnCount - 1)); // Total spacing

            // Calculate the width each column would get if we used full screen width
            final availableWidth = constraints.maxWidth - totalSpacing;
            final naturalColumnWidth = availableWidth / columnCount;

            // If natural column width is less than minimum, use minimum with scroll
            // Otherwise, let columns expand to fill the space
            final columnWidth = naturalColumnWidth < minColumnWidth
                ? minColumnWidth
                : naturalColumnWidth;

            // Calculate total width needed
            final totalWidth = (columnWidth * columnCount) + totalSpacing;

            return Listener(
              onPointerMove: (event) {
                if (_scrollController.hasClients) {
                  _handleDragUpdate(
                    DragUpdateDetails(
                      globalPosition: event.position,
                      delta: event.delta,
                    ),
                    context,
                  );
                }
              },
              onPointerUp: (_) => _stopScrolling(),
              onPointerCancel: (_) => _stopScrolling(),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: totalWidth,
                  height: constraints.maxHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: padding / 2,
                    vertical: 16.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildColumn(
                        context,
                        'To Do',
                        TaskStatus.todo,
                        Colors.grey,
                        widget.tasks
                            .where((task) => task.status == TaskStatus.todo)
                            .toList(),
                        columnWidth,
                      ),
                      const SizedBox(width: columnSpacing),
                      _buildColumn(
                        context,
                        'In Progress',
                        TaskStatus.inProgress,
                        Colors.blue,
                        widget.tasks
                            .where(
                                (task) => task.status == TaskStatus.inProgress)
                            .toList(),
                        columnWidth,
                      ),
                      const SizedBox(width: columnSpacing),
                      _buildColumn(
                        context,
                        'Done',
                        TaskStatus.done,
                        Colors.green,
                        widget.tasks
                            .where((task) => task.status == TaskStatus.done)
                            .toList(),
                        columnWidth,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildColumn(BuildContext context, String title, TaskStatus status,
      Color color, List<Task> tasks, double width) {
    return DragTarget<Task>(
      builder: (context, candidateData, rejectedData) {
        return BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TasksLoaded) {
              // Use the helper method to get tasks while maintaining order
              final columnTasks = state.getTasksByStatus(status);
              return _buildColumnContent(
                context,
                title,
                status,
                color,
                columnTasks,
                width,
                state.updatingTaskIds,
              );
            }
            return _buildColumnContent(
              context,
              title,
              status,
              color,
              tasks,
              width,
              {},
            );
          },
        );
      },
      onWillAccept: (data) {
        if (!mounted) return false;
        final currentState = context.read<TaskBloc>().state;

        // Check if the task is currently being updated
        if (currentState is TasksLoaded &&
            data != null &&
            currentState.updatingTaskIds.contains(data.id)) {
          return false;
        }

        return data?.status != status;
      },
      onAccept: (data) {
        if (!mounted) return;
        context.read<TaskBloc>().add(
              UpdateTaskStatus(task: data, newStatus: status),
            );
      },
    );
  }

  Widget _buildColumnContent(
      BuildContext context,
      String title,
      TaskStatus status,
      Color color,
      List<Task> tasks,
      double width,
      Set<String> updatingTaskIds) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tasks.length.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: tasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: BlocBuilder<TaskBloc, TaskState>(
                        builder: (context, state) {
                          final isUpdating = state is TasksLoaded &&
                              state.updatingTaskIds.contains(task.id);

                          return Stack(
                            children: [
                              Opacity(
                                opacity: isUpdating ? 0.6 : 1.0,
                                child: LongPressDraggable<Task>(
                                  data: task,
                                  feedback: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: width - 32,
                                      child: TaskCard(
                                        task: task,
                                        commentCount: task.comments.length,
                                        onTap: (context) => _showTaskDetails(
                                          context,
                                          task,
                                          context.read<CommentBloc>(),
                                        ),
                                        isDragging: true,
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: TaskCard(
                                      task: task,
                                      commentCount: task.comments.length,
                                      onTap: (context) => _showTaskDetails(
                                        context,
                                        task,
                                        context.read<CommentBloc>(),
                                      ),
                                    ),
                                  ),
                                  // Disable dragging while updating
                                  maxSimultaneousDrags: isUpdating ? 0 : 1,
                                  child: TaskCard(
                                    task: task,
                                    commentCount: task.comments.length,
                                    onTap: (context) => _showTaskDetails(
                                      context,
                                      task,
                                      context.read<CommentBloc>(),
                                    ),
                                  ),
                                ),
                              ),
                              if (isUpdating)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(
    BuildContext context,
    Task task,
    CommentBloc commentBloc,
  ) {
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TaskBloc>()),
          BlocProvider.value(value: commentBloc),
          BlocProvider.value(value: context.read<TimeTrackingBloc>()),
        ],
        child: TaskDetailsDialog(
          task: task,
          commentRepository: getIt(),
          timeEntryRepository: getIt<TimeEntryRepository>(),
        ),
      ),
    );
  }
}
