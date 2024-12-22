class TimeEntry {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;

  TimeEntry({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    Duration? duration,
  }) : duration = duration ??
            (endTime != null
                ? endTime.difference(startTime)
                : DateTime.now().difference(startTime));

  bool get isRunning => endTime == null;
}
