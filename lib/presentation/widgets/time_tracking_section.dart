import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:innoscripta/presentation/blocs/time_tracking/time_tracking_bloc.dart';
import 'package:innoscripta/presentation/blocs/time_tracking/time_tracking_event.dart';
import 'package:innoscripta/presentation/blocs/time_tracking/time_tracking_state.dart';

class TimeTrackingSection extends StatefulWidget {
  final String taskId;

  const TimeTrackingSection({
    super.key,
    required this.taskId,
  });

  @override
  State<TimeTrackingSection> createState() => _TimeTrackingSectionState();
}

class _TimeTrackingSectionState extends State<TimeTrackingSection> {
  Timer? _timer;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    context.read<TimeTrackingBloc>().add(LoadTimeTracking(widget.taskId));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _currentDuration = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TimeTrackingBloc, TimeTrackingState>(
      listener: (context, state) {
        if (state is TimeTrackingLoaded) {
          if (state.currentTimer != null && _timer == null) {
            _currentDuration =
                DateTime.now().difference(state.currentTimer!.startTime);
            _startTimer();
          } else if (state.currentTimer == null && _timer != null) {
            _stopTimer();
          }
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (state is TimeTrackingLoaded) ...[
              _buildTimerCard(context, state),
              const SizedBox(height: 24),
              _buildTimeEntryList(context, state),
            ] else if (state is TimeTrackingLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildTimerCard(BuildContext context, TimeTrackingLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRunning = state.currentTimer != null;
    final displayDuration = isRunning ? _currentDuration : state.totalDuration;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isRunning ? 'Current Session' : 'Total Time',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary, // Using app's primary color
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatDuration(displayDuration),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          if (isRunning) ...[
            const SizedBox(height: 8),
            Text(
              'Total: ${_formatDuration(state.totalDuration + _currentDuration)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isRunning) {
                  context
                      .read<TimeTrackingBloc>()
                      .add(StopTimer(state.currentTimer!.id));
                } else {
                  context
                      .read<TimeTrackingBloc>()
                      .add(StartTimer(widget.taskId));
                }
              },
              icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(
                isRunning ? 'Stop Timer' : 'Start Timer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning
                    ? const Color(0xFFB71C1C) // Deep dark red
                    : theme.colorScheme.primary, // Using app's primary color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEntryList(BuildContext context, TimeTrackingLoaded state) {
    final theme = Theme.of(context);
    final entries = state.timeEntries.where((e) => !e.isRunning).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No time entries yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Entries',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(entry.startTime),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'Duration: ${_formatDuration(entry.duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
