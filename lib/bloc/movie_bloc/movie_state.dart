import 'package:equatable/equatable.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/genre_model.dart';

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

class MovieSearchLoaded extends MovieState {
  final List<MovieModel> movies;
  MovieSearchLoaded(this.movies);

  @override
  List<Object?> get props => [movies];
}

class MovieError extends MovieState {
  final String message;
  MovieError(this.message);

  @override
  List<Object?> get props => [message];
}