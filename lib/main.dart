import 'package:cinemate/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bloc/auth_bloc/auth_bloc.dart';
import 'bloc/auth_bloc/auth_event.dart';
import 'bloc/movie_bloc/movie_bloc.dart';
import 'data/services/movie_service.dart';
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
      ], 
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Cinemate',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color (0xFF1A1A2E),
                brightness: Brightness.dark,
              ),
            useMaterial3: true,
            ),
            routerConfig: AppRouter.router(context),
          );
        }
      ),
    );
  }
}