import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/di/service_locator.dart';
import '../screens/completed_tasks_screen.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/comment/comment_bloc.dart';
import '../blocs/theme/theme_cubit.dart';

class CompletedTasksRoute extends StatelessWidget {
  const CompletedTasksRoute({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<TaskBloc>(
            create: (context) => getIt<TaskBloc>(),
          ),
          BlocProvider<TimeTrackingBloc>(
            create: (context) => getIt<TimeTrackingBloc>(),
          ),
          BlocProvider<CommentBloc>(
            create: (context) => getIt<CommentBloc>(),
          ),
          // Inherit the ThemeCubit from the parent context
          BlocProvider.value(
            value: context.read<ThemeCubit>(),
          ),
        ],
        child: const CompletedTasksScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CompletedTasksScreen();
  }
}
