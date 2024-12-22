import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'infrastructure/di/service_locator.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/widgets/bloc_providers_wrapper.dart';

import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => getIt<ThemeCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Task Tracker',
            themeMode: themeMode,
            theme: ThemeData.light(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.lightSurface,
                onSurface: AppColors.lightOnSurface,
                error: AppColors.lightError,
              ),
              scaffoldBackgroundColor: AppColors.lightBackground,
              cardColor: AppColors.lightSurface,
              dialogBackgroundColor: AppColors.lightSurface,
              dividerColor: AppColors.lightDivider,
              textTheme: const TextTheme(
                titleLarge: TextStyle(color: AppColors.primary),
                titleMedium: TextStyle(color: AppColors.lightTitleMedium),
                bodyMedium: TextStyle(color: AppColors.lightBodyMedium),
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.darkSurface,
                onSurface: AppColors.darkOnSurface,
                error: AppColors.darkError,
              ),
              scaffoldBackgroundColor: AppColors.darkBackground,
              cardColor: AppColors.darkCard,
              dialogBackgroundColor: AppColors.darkCard,
              dividerColor: AppColors.darkDivider,
              textTheme: const TextTheme(
                titleLarge: TextStyle(color: AppColors.primary),
                titleMedium: TextStyle(color: AppColors.darkTitleMedium),
                bodyMedium: TextStyle(color: AppColors.darkBodyMedium),
              ),
            ),
            home: const BlocProvidersWrapper(
              child: HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
