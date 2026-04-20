import 'package:equatable/equatable.dart';

/// Sorting options surfaced in the Search filter bottom sheet.
/// Each value maps to a TMDB API parameter via [MovieSortOptionX.apiValue],
/// except [trending] which uses the dedicated /trending/movie/week endpoint.
enum MovieSortOption { popular, topRated, latest, longest, trending }

extension MovieSortOptionX on MovieSortOption {
  /// Human-readable label shown in the filter sheet and active-filter chips.
  String get label {
    switch (this) {
      case MovieSortOption.popular:  return 'Popular';
      case MovieSortOption.topRated: return 'Top Rated';
      case MovieSortOption.latest:   return 'Recent';
      case MovieSortOption.longest:  return 'Longest';
      case MovieSortOption.trending: return 'Trending';
    }
  }

  /// TMDB sort_by query param.
  /// Returns empty string for [trending] — routed to a separate endpoint.
  String get apiValue {
    switch (this) {
      case MovieSortOption.popular:  return 'popularity.desc';
      case MovieSortOption.topRated: return 'vote_average.desc';
      case MovieSortOption.latest:   return 'release_date.desc';
      case MovieSortOption.longest:  return 'runtime.desc';
      case MovieSortOption.trending: return '';
    }
  }
}

/// Immutable filter state carried from SearchTab → BLoC → MovieService.
///
/// [sortBy]     — how to order results (default: popular).
/// [genreIds]   — list of TMDB genre IDs (empty = all genres).
///               Multi-select: TMDB /discover supports comma-separated IDs.
/// [genreNames] — parallel display names for [genreIds], used in active chips.
///               NOT included in equality — equality is based on [sortBy] + [genreIds].
///
/// Use [copyWith] to produce modified copies.
/// Use [isDefault] to check whether any non-default filter is active.
class MovieFilter extends Equatable {
  final MovieSortOption sortBy;
  final List<int> genreIds;
  final List<String> genreNames;

  const MovieFilter({
    this.sortBy = MovieSortOption.popular,
    this.genreIds = const [],
    this.genreNames = const [],
  });

  /// True when the filter is in its default state (popular sort, no genres).
  bool get isDefault => sortBy == MovieSortOption.popular && genreIds.isEmpty;

  /// Returns a new [MovieFilter] with specified fields replaced.
  /// To clear all genre selections, pass empty lists explicitly:
  ///   filter.copyWith(genreIds: [], genreNames: [])
  MovieFilter copyWith({
    MovieSortOption? sortBy,
    List<int>? genreIds,
    List<String>? genreNames,
  }) =>
      MovieFilter(
        sortBy: sortBy ?? this.sortBy,
        genreIds: genreIds ?? this.genreIds,
        genreNames: genreNames ?? this.genreNames,
      );

  // genreNames is intentionally excluded — it's a display-only label.
  // Equality and caching depend only on sortBy + genreIds.
  @override
  List<Object?> get props => [sortBy, genreIds];
}
