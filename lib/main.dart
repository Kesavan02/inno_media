import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/navigation/app_route_observer.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dynamic_form/presentation/bloc/dynamic_form_bloc.dart';
import 'features/dynamic_form/presentation/bloc/dynamic_form_event.dart';
import 'features/feed/presentation/bloc/feed_bloc.dart';
import 'features/feed/presentation/bloc/feed_event.dart';
import 'features/navigation/presentation/pages/main_shell_page.dart';
import 'features/reels/presentation/bloc/reels_bloc.dart';
import 'features/reels/presentation/bloc/reels_event.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization notice: $e');
  }
  await di.initDependencies();
  runApp(const InnoMediaApp());
}

class InnoMediaApp extends StatelessWidget {
  const InnoMediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthSessionEvent()),
        ),
        BlocProvider<FeedBloc>(
          create: (_) => di.sl<FeedBloc>()..add(LoadFeedInitialEvent()),
        ),
        BlocProvider<ReelsBloc>(
          create: (_) => di.sl<ReelsBloc>()..add(LoadReelsEvent()),
        ),
        BlocProvider<DynamicFormBloc>(
          create: (_) => di.sl<DynamicFormBloc>()..add(LoadDefaultFormConfigEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'InnoMedia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorObservers: [appRouteObserver],
        home: const AppRootRouter(),
      ),
    );
  }
}

class AppRootRouter extends StatelessWidget {
  const AppRootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is Authenticated) {
          return const MainShellPage();
        }

        return const LoginPage();
      },
    );
  }
}
