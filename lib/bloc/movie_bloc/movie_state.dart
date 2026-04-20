import 'package:equatable/equatable.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/movie_filter.dart';

abstract class MovieState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieHomeLoaded extends MovieState {
  final List<MovieModel> nowPlaying;
  final List<MovieModel> popular;

  MovieHomeLoaded({required this.nowPlaying, required this.popular});

  @override
  List<Object?> get props => [nowPlaying, popular];
}

class MoviePopularLoaded extends MovieState {
  final List<MovieModel> movies;
  MoviePopularLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class MovieNowPlayingLoaded extends MovieState {
  final List<MovieModel> movies;
  MovieNowPlayingLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class MovieTopRatedLoaded extends MovieState {
  final List<MovieModel> movies;
  MovieTopRatedLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class MovieUpcomingLoaded extends MovieState {
  final List<MovieModel> movies;
  MovieUpcomingLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class MovieGenresLoaded extends MovieState {
  final List<GenreModel> genres;
  MovieGenresLoaded(this.genres);

  @override
  List<Object?> get props => [genres];
}

class MovieGenreLoaded extends MovieState {
  final List<MovieModel> movies;
  MovieGenreLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class MovieSearchLoaded extends MovieState {
  final List<MovieModel> titleMovies;
  final List<MovieModel> actorMovies;
  final String? actorName;

  MovieSearchLoaded({
    this.titleMovies = const [],
    this.actorMovies = const [],
    this.actorName,
  });

  bool get hasTitle => titleMovies.isNotEmpty;
  bool get hasActor => actorMovies.isNotEmpty && actorName != null;
  bool get isEmpty  => titleMovies.isEmpty && actorMovies.isEmpty;

  @override
  List<Object?> get props => [titleMovies, actorMovies, actorName];
}

class MovieDiscoverLoaded extends MovieState {
  final List<MovieModel> movies;
  final MovieFilter filter;
  MovieDiscoverLoaded(this.movies, this.filter);

  @override
  List<Object?> get props => [movies, filter];
}

class MovieError extends MovieState {
  final String message;
  MovieError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State emitted by [MovieFetchListPage].
/// Carries only the newly fetched page — [MovieListScreen] accumulates pages
/// in its own local state, keeping the BLoC free of pagination concerns.
///
/// [hasMore] is false when the fetched page returned fewer than 20 results,
/// indicating TMDB has no further pages for this query.
class MovieListLoaded extends MovieState {
  final List<MovieModel> movies; // this page's results only
  final int page;
  final bool hasMore;

  MovieListLoaded({
    required this.movies,
    required this.page,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [movies, page, hasMore];
}