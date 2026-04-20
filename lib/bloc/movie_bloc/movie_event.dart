import 'package:equatable/equatable.dart';
import '../../data/models/movie_filter.dart';

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

class MovieFetchByGenre extends MovieEvent {
  final int genreId;
  MovieFetchByGenre(this.genreId);

  @override
  List<Object?> get props => [genreId];
}

class MovieClearSearch extends MovieEvent {}

class MovieSearch extends MovieEvent {
  final String query;
  MovieSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class MovieDiscover extends MovieEvent {
  final MovieFilter filter;
  MovieDiscover(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Unified paginated fetch event used exclusively by [MovieListScreen].
/// The screen owns its local movie list and accumulates pages.
/// [page] starts at 1; the BLoC returns only the requested page's results.
/// [genreFilter] — when non-null on a category page (not genre_*), the BLoC
/// switches to /discover with the category's sort + this genre ID, giving
/// accurate server-side results instead of a client-side filter on 20 items.
class MovieFetchListPage extends MovieEvent {
  final String category;
  final int page;
  final MovieSortOption sortOption;
  final int? genreFilter;

  MovieFetchListPage({
    required this.category,
    this.page = 1,
    this.sortOption = MovieSortOption.popular,
    this.genreFilter,
  });

  @override
  List<Object?> get props => [category, page, sortOption, genreFilter];
}