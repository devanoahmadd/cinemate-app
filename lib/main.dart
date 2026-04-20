import 'package:cinemate/core/routes/app_router.dart';
import 'package:cinemate/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bloc/auth_bloc/auth_bloc.dart';
import 'bloc/auth_bloc/auth_event.dart';
import 'bloc/movie_bloc/movie_bloc.dart';
import 'bloc/tv_bloc/tv_bloc.dart';
import 'bloc/watchlist_bloc/watchlist_bloc.dart';
import 'data/services/movie_service.dart';
import 'data/services/tv_service.dart';
import 'data/services/watchlist_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CinemateApp());
}

class CinemateApp extends StatelessWidget {
  const CinemateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => MovieBloc(MovieService()),
        ),
        BlocProvider(
          create: (_) => TvBloc(TvService()),
        ),
        BlocProvider(
          create: (_) => WatchlistBloc(WatchlistService()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Cinemate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: AppRouter.router(context),
          );
        }
      ),
    );
  }
}