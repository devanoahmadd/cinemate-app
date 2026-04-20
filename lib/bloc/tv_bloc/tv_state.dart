import 'package:equatable/equatable.dart';
import '../../data/models/tv_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/movie_filter.dart';

abstract class TvState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TvInitial extends TvState {}

class TvLoading extends TvState {}

/// Emitted after [TvFetchHome] — carries airingToday + popular for the
/// Home tab TV section. Parallel to [MovieHomeLoaded].
class TvHomeLoaded extends TvState {
  final List<TvModel> airingToday;
  final List<TvModel> popular;

  TvHomeLoaded({required this.airingToday, required this.popular});

  @override
  List<Object?> get props => [airingToday, popular];
}

class TvPopularLoaded extends TvState {
  final List<TvModel> shows;
  TvPopularLoaded(this.shows);

  @override
  List<Object?> get props => [shows];
}

class TvAiringTodayLoaded extends TvState {
  final List<TvModel> shows;
  TvAiringTodayLoaded(this.shows);

  @override
  List<Object?> get props => [shows];
}

class TvOnTheAirLoaded extends TvState {
  final List<TvModel> shows;
  TvOnTheAirLoaded(this.shows);

  @override
  List<Object?> get props => [shows];
}

class TvTopRatedLoaded extends TvState {
  final List<TvModel> shows;
  TvTopRatedLoaded(this.shows);

  @override
  List<Object?> get props => [shows];
}

class TvGenresLoaded extends TvState {
  final List<GenreModel> genres;
  TvGenresLoaded(this.genres);

  @override
  List<Object?> get props => [genres];
}

/// Emitted after [TvFetchByGenre].
class TvGenreLoaded extends TvState {
  final List<TvModel> shows;
  TvGenreLoaded(this.shows);

  @override
  List<Object?> get props => [shows];
}

class TvSearchLoaded extends TvState {
  final List<TvModel> titleShows;
  final List<TvModel> actorShows;
  final String? actorName;

  TvSearchLoaded({
    this.titleShows = const [],
    this.actorShows = const [],
    this.actorName,
  });

  bool get hasTitle => titleShows.isNotEmpty;
  bool get hasActor => actorShows.isNotEmpty && actorName != null;
  bool get isEmpty  => titleShows.isEmpty && actorShows.isEmpty;

  @override
  List<Object?> get props => [titleShows, actorShows, actorName];
}

class TvDiscoverLoaded extends TvState {
  final List<TvModel> shows;
  final MovieFilter filter;
  TvDiscoverLoaded(this.shows, this.filter);

  @override
  List<Object?> get props => [shows, filter];
}

class TvError extends TvState {
  final String message;
  TvError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State emitted by [TvFetchListPage].
/// Carries only the newly fetched page — [TvListScreen] accumulates pages
/// in its own local state, keeping the BLoC free of pagination concerns.
///
/// [hasMore] is false when the fetched page returned fewer than 20 results,
/// indicating TMDB has no further pages for this query.
class TvListLoaded extends TvState {
  final List<TvModel> shows; // this page's results only
  final int page;
  final bool hasMore;

  TvListLoaded({
    required this.shows,
    required this.page,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [shows, page, hasMore];
}
