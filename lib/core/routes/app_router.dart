import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';
import '../../bloc/auth_bloc/auth_state.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/movie/movie_list_screen.dart';
import '../../screens/movie/movie_detail_screen.dart';

class AppRouter {
    static final String splash      = '/';
    static final String login       = '/login';
    static final String register    = '/register';
    static final String home        = '/home';
    static final String movieList   = '/movies';
    static final String movieDetail = '/movies/:id';
    static final String profile     = '/profile';

    static GoRouter router(BuildContext context) {
        return GoRouter(
            initialLocation: splash,
            redirect: (context, state) {
                final authState = context.read<AuthBloc>().state;
                final isAuth = authState is AuthAuthenticated;
                final isOnAuth = state.matchedLocation == login || 
                    state.matchedLocation == register || 
                    state.matchedLocation == splash;
                
                if (!isAuth && !isOnAuth) return login;
                if (isAuth && isOnAuth) return home;
                return null;
            },
            routes: [
                GoRoute(
                    path: splash,
                    builder: (_, _) => const SplashScreen(),
                ),
                GoRoute(
                    path: login,
                    builder: (_, _) => const LoginScreen(),
                ),
                GoRoute(
                    path: register,
                    builder: (_, _) => const RegisterScreen(),
                ),
                GoRoute(
                    path: home,
                    builder: (_, _) => const MainScreen(),
                ),
                GoRoute(
                    path: movieList,
                    builder: (context, state) {
                      final category = state.extra as String? ?? 'popular';
                      return MovieListScreen(category: category);
                    },
                ),
                GoRoute(
                    path: movieDetail,
                    builder: (context, state) {
                      final movie = state.extra as Map<String, dynamic>;
                      return MovieDetailScreen(movie: movie);
                    },
                ),
            ],
        );
    }
}