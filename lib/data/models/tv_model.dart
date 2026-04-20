/// TV show list-item model — from TMDB list/search/discover endpoints.
///
/// Parallel to [MovieModel] but uses TV-specific field names:
///   - [name]         instead of `title`
///   - [firstAirDate] instead of `release_date`
///   - [originCountry] extra field not present on movies
///   - [voteCount]    added here (MovieModel omits it for list items)
///
/// Use [displayTitle] and [releaseYear] in shared widgets so the same
/// widget can render both movies and TV shows without branching.
class TvModel {
  final int id;

  /// Show title from TMDB `name` field.
  final String name;

  /// Original-language title from TMDB `original_name` field.
  final String originalName;

  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;

  /// ISO date string "YYYY-MM-DD", e.g. "2019-04-14". Empty when unknown.
  final String firstAirDate;

  final List<int> genreIds;

  /// ISO 3166-1 alpha-2 country codes, e.g. ["US", "GB"].
  final List<String> originCountry;

  const TvModel({
    required this.id,
    required this.name,
    required this.originalName,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.firstAirDate,
    required this.genreIds,
    required this.originCountry,
  });

  factory TvModel.fromJson(Map<String, dynamic> json) {
    return TvModel(
      id:           json['id']            ?? 0,
      name:         json['name']          ?? '',
      originalName: json['original_name'] ?? '',
      overview:     json['overview']      ?? '',
      posterPath:   json['poster_path']   ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage:  (json['vote_average'] ?? 0).toDouble(),
      voteCount:    json['vote_count']    ?? 0,
      firstAirDate: json['first_air_date'] ?? '',
      genreIds:     List<int>.from(json['genre_ids'] ?? []),
      originCountry: List<String>.from(json['origin_country'] ?? []),
    );
  }

  // ── URL helpers ────────────────────────────────────────────────

  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropUrl =>
      backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w780$backdropPath' : '';

  // ── Shared-widget compatibility getters ────────────────────────

  /// Alias for [name]. Lets shared widgets call `.displayTitle` on both
  /// [TvModel] and [MovieModel] without needing to know the media type.
  String get displayTitle => name;

  /// Four-digit year extracted from [firstAirDate], e.g. "2019".
  /// Returns an empty string when the date is unavailable.
  String get releaseYear =>
      firstAirDate.length >= 4 ? firstAirDate.substring(0, 4) : '';
}
