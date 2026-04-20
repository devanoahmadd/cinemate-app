import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';
import '../../bloc/auth_bloc/auth_state.dart';
import '../../bloc/movie_bloc/movie_bloc.dart';
import '../../bloc/tv_bloc/tv_bloc.dart';
import '../../data/services/movie_service.dart';
import '../../data/services/tv_service.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/movie/movie_list_screen.dart';
import '../../screens/movie/movie_detail_screen.dart';
import '../../screens/tv/tv_list_screen.dart';
import '../../screens/tv/tv_detail_screen.dart';
import '../../screens/profile/watchlist_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/change_password_screen.dart';
import '../../screens/movie/collection_screen.dart';
import '../../screens/movie/cast_screen.dart';
import '../../screens/movie/reviews_screen.dart';
import '../../screens/movie/media_related_screen.dart';
import '../../data/models/cast_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/movie_model.dart';

class AppRouter {
    static final String splash      = '/';
    static final String login       = '/login';
    static final String register    = '/register';
    static final String home        = '/home';
    static final String movieList   = '/movies';
    static final String movieDetail = '/movies/:id';
    static final String profile     = '/profile';
    static final String tvList           = '/tv';
    static final String tvDetail         = '/tv/:id';
    static final String watchlist        = '/watchlist';
    static final String editProfile      = '/edit-profile';
    static final String changePassword   = '/change-password';
    static final String collection       = '/collection';
    static final String castAll          = '/cast';
    static final String reviewsAll       = '/reviews';
    static final String relatedAll       = '/related';

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
                      // Provide a dedicated MovieBloc instance so MovieListScreen
                      // is fully isolated from the global BLoC used by Home/Search.
                      // The local BLoC is auto-disposed when the route is popped.
                      return BlocProvider(
                        create: (_) => MovieBloc(MovieService()),
                        child: MovieListScreen(category: category),
                      );
                    },
                ),
                GoRoute(
                    path: movieDetail,
                    builder: (context, state) {
                      final movie = state.extra as Map<String, dynamic>;
                      return MovieDetailScreen(movie: movie);
                    },
                ),
                GoRoute(
                    path: tvList,
                    builder: (context, state) {
                      final category = state.extra as String? ?? 'popular';
                      // Dedicated TvBloc instance — isolated from the global
                      // BLoC used by Home/Search. Auto-disposed on pop.
                      return BlocProvider(
                        create: (_) => TvBloc(TvService()),
                        child: TvListScreen(category: category),
                      );
                    },
                ),
                GoRoute(
                    path: tvDetail,
                    builder: (context, state) {
                      final show = state.extra as Map<String, dynamic>;
                      return TvDetailScreen(show: show);
                    },
                ),
                GoRoute(
                    path: watchlist,
                    builder: (_, _) => const WatchlistScreen(),
                ),
                GoRoute(
                    path: editProfile,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return EditProfileScreen(
                        currentName: args['name'] as String,
                        currentPhotoUrl: args['photoUrl'] as String?,
                      );
                    },
                ),
                GoRoute(
                    path: changePassword,
                    builder: (_, _) => const ChangePasswordScreen(),
                ),
                GoRoute(
                    path: collection,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return CollectionScreen(
                        collectionId:   args['collectionId']   as int,
                        collectionName: args['collectionName'] as String,
                      );
                    },
                ),
                GoRoute(
                    path: castAll,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return CastScreen(
                        movieTitle: args['movieTitle'] as String,
                        cast:       args['cast']       as List<CastModel>,
                      );
                    },
                ),
                GoRoute(
                    path: reviewsAll,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return ReviewsScreen(
                        movieId:        args['movieId']        as int,
                        movieTitle:     args['movieTitle']     as String,
                        voteAverage:    args['voteAverage']    as double,
                        voteCount:      args['voteCount']      as int,
                        initialReviews: args['initialReviews'] as List<ReviewModel>,
                      );
                    },
                ),
                GoRoute(
                    path: relatedAll,
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>;
                      return MediaRelatedScreen(
                        movieId:       args['movieId']       as int,
                        movieTitle:    args['movieTitle']    as String,
                        type:          args['type']          as MediaRelatedType,
                        initialMovies: args['initialMovies'] as List<MovieModel>,
                      );
                    },
                ),
            ],
        );
    }
}