import 'package:uuid/uuid.dart';
import '../../domain/entities/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';
import '../exceptions/repository_exception.dart';

class InMemoryTimeEntryRepository implements TimeEntryRepository {
  final Map<String, TimeEntry> _timeEntries = {};
  final _uuid = const Uuid();

  @override
  Future<TimeEntry> startTimer(String taskId) async {
    // Check if there's already a running timer for this task
    final runningTimer = await getCurrentRunningTimer(taskId);
    if (runningTimer != null) {
      throw RepositoryException('A timer is already running for this task');
    }

    final newEntry = TimeEntry(
      id: _uuid.v4(),
      taskId: taskId,
      startTime: DateTime.now(),
    );
    _timeEntries[newEntry.id] = newEntry;
    return newEntry;
  }

  @override
  Future<TimeEntry> stopTimer(String timeEntryId) async {
    final entry = _timeEntries[timeEntryId];
    if (entry == null) {
      throw RepositoryException('Time entry not found with id: $timeEntryId');
    }
    if (!entry.isRunning) {
      throw RepositoryException('Timer is not running');
    }

    final stoppedEntry = TimeEntry(
      id: entry.id,
      taskId: entry.taskId,
      startTime: entry.startTime,
      endTime: DateTime.now(),
    );
    _timeEntries[timeEntryId] = stoppedEntry;
    return stoppedEntry;
  }

  @override
  Future<List<TimeEntry>> getTimeEntriesForTask(String taskId) async {
    return _timeEntries.values
        .where((entry) => entry.taskId == taskId)
        .toList();
  }

  @override
  Future<Duration> getTotalDurationForTask(String taskId) async {
    final entries = await getTimeEntriesForTask(taskId);
    return entries.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );
  }

  @override
  Future<TimeEntry?> getCurrentRunningTimer(String taskId) async {
    try {
      return _timeEntries.values
          .firstWhere((entry) => entry.taskId == taskId && entry.isRunning);
    } catch (e) {
      return null;
    }
  }
}
