import '../entities/time_entry.dart';

abstract class TimeEntryRepository {
  Future<TimeEntry> startTimer(String taskId);
  Future<TimeEntry> stopTimer(String timeEntryId);
  Future<List<TimeEntry>> getTimeEntriesForTask(String taskId);
  Future<Duration> getTotalDurationForTask(String taskId);
  Future<TimeEntry?> getCurrentRunningTimer(String taskId);
}
