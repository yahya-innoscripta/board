import 'package:get_it/get_it.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/repositories/time_entry_repository.dart';
import '../repositories/todoist_task_repository.dart';
import '../repositories/todoist_comment_repository.dart';
import '../repositories/in_memory_time_entry_repository.dart';
import '../../presentation/blocs/task/task_bloc.dart';
import '../../presentation/blocs/time_tracking/time_tracking_bloc.dart';
import '../../presentation/blocs/comment/comment_bloc.dart';
import '../../presentation/blocs/theme/theme_cubit.dart';
import 'package:dio/dio.dart';
import 'dio_config.dart';

final getIt = GetIt.instance;

const String apiToken = '48361b9da9e49af684d242af78d594f213edd3b6';

void setupServiceLocator() {
  // Dio instances
  getIt.registerLazySingleton<Dio>(
    () => DioConfig.createRestDio(apiToken),
    instanceName: 'restDio',
  );

  getIt.registerLazySingleton<Dio>(
    () => DioConfig.createSyncDio(apiToken),
    instanceName: 'syncDio',
  );

  // Repositories
  getIt.registerLazySingleton<TaskRepository>(
    () => TodoistTaskRepository(
      apiToken: apiToken,
      restDio: getIt<Dio>(instanceName: 'restDio'),
      syncDio: getIt<Dio>(instanceName: 'syncDio'),
    ),
  );

  getIt.registerLazySingleton<CommentRepository>(
    () => TodoistCommentRepository(
      token: apiToken,
    ),
  );

  getIt.registerLazySingleton<TimeEntryRepository>(
    () => InMemoryTimeEntryRepository(),
  );

  // Blocs
  getIt.registerFactory<TaskBloc>(
    () => TaskBloc(taskRepository: getIt<TaskRepository>()),
  );

  getIt.registerFactory<TimeTrackingBloc>(
    () => TimeTrackingBloc(timeEntryRepository: getIt<TimeEntryRepository>()),
  );

  getIt.registerFactory<CommentBloc>(
    () => CommentBloc(commentRepository: getIt<CommentRepository>()),
  );

  getIt.registerFactory<ThemeCubit>(() => ThemeCubit());
}
