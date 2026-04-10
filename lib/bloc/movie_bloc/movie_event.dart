import 'package:equatable/equatable.dart';

abstract class MovieEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MovieFetchPopular extends MovieEvent {}

class MovieFetchNowPlaying extends MovieEvent {}

class MovieFetchTopRated extends MovieEvent {}

class MovieFetchUpcoming extends MovieEvent {}

class MovieFetchGenres extends MovieEvent {}

class MovieFetchHome extends MovieEvent {}

class MovieClearSearch extends MovieEvent {}

class MovieSearch extends MovieEvent {
  final String query;
  MovieSearch(this.query);

  @override
  List<Object?> get props => [query];
}