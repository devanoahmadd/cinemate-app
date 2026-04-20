import 'package:equatable/equatable.dart';
import '../../data/models/movie_filter.dart';

abstract class TvEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Fetches airingToday + popular in parallel for the Home tab TV section.
class TvFetchHome extends TvEvent {}

class TvFetchPopular extends TvEvent {}

/// Shows with new episodes today — equivalent of MovieFetchNowPlaying.
class TvFetchAiringToday extends TvEvent {}

/// Shows currently airing across the next 7 days.
class TvFetchOnTheAir extends TvEvent {}

class TvFetchTopRated extends TvEvent {}

class TvFetchGenres extends TvEvent {}

class TvFetchByGenre extends TvEvent {
  final int genreId;
  TvFetchByGenre(this.genreId);

  @override
  List<Object?> get props => [genreId];
}

class TvSearch extends TvEvent {
  final String query;
  TvSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class TvClearSearch extends TvEvent {}

class TvDiscover extends TvEvent {
  final MovieFilter filter;
  TvDiscover(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Unified paginated fetch event used exclusively by [TvListScreen].
/// The screen owns its local show list and accumulates pages.
/// [page] starts at 1; the BLoC returns only the requested page's results.
class TvFetchListPage extends TvEvent {
  final String category;
  final int page;
  final MovieSortOption sortOption;

  TvFetchListPage({
    required this.category,
    this.page = 1,
    this.sortOption = MovieSortOption.popular,
  });

  @override
  List<Object?> get props => [category, page, sortOption];
}
