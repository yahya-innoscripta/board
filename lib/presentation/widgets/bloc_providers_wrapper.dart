import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/comment/comment_bloc.dart';
import '../../infrastructure/di/service_locator.dart';

class BlocProvidersWrapper extends StatelessWidget {
  final Widget child;

  const BlocProvidersWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
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
      ],
      child: child,
    );
  }
}
