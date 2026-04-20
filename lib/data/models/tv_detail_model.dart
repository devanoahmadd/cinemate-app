import 'movie_detail_model.dart';

/// Full TV show detail — from TMDB endpoint `/tv/{id}`.
///
/// Distinct from [TvModel] (which is used for list responses).
/// Reuses [MovieGenre], [SpokenLanguage], [ProductionCompany] from
/// [movie_detail_model.dart] — these are structurally identical for TV.
///
/// TV-exclusive additions over the movie equivalent:
///   - [numberOfSeasons], [numberOfEpisodes], [episodeRunTime]
///   - [type]           — Scripted / Reality / Documentary / etc.
///   - [inProduction]   — whether new episodes are still being made
///   - [lastAirDate]    — date of most recent episode
///   - [networks]       — broadcasting networks (Netflix, HBO, etc.)
///   - [seasons]        — per-season metadata (poster, episode count, air date)
class TvDetailModel {
  final int id;
  final String name;
  final String originalName;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String firstAirDate;
  final String lastAirDate;

  /// e.g. "Returning Series", "Ended", "Canceled", "In Production", "Planned"
  final String status;

  final String tagline;
  final bool inProduction;
  final int numberOfSeasons;
  final int numberOfEpisodes;

  /// TMDB returns an array because episodes can vary in length.
  /// e.g. [] | [45] | [40, 45]
  final List<int> episodeRunTime;

  /// e.g. "Scripted", "Reality", "Documentary", "News", "Talk Show", "Miniseries"
  final String type;

  final String originalLanguage;
  final List<MovieGenre> genres;
  final List<SpokenLanguage> spokenLanguages;
  final List<TvNetwork> networks;
  final List<SeasonInfo> seasons;
  final List<ProductionCompany> productionCompanies;

  const TvDetailModel({
    required this.id,
    required this.name,
    required this.originalName,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.status,
    required this.tagline,
    required this.inProduction,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.episodeRunTime,
    required this.type,
    required this.originalLanguage,
    required this.genres,
    required this.spokenLanguages,
    required this.networks,
    required this.seasons,
    required this.productionCompanies,
  });

  factory TvDetailModel.fromJson(Map<String, dynamic> json) {
    return TvDetailModel(
      id:               json['id']               ?? 0,
      name:             json['name']             ?? '',
      originalName:     json['original_name']    ?? '',
      overview:         json['overview']         ?? '',
      posterPath:       json['poster_path']      ?? '',
      backdropPath:     json['backdrop_path']    ?? '',
      voteAverage:      (json['vote_average']    ?? 0).toDouble(),
      voteCount:        json['vote_count']       ?? 0,
      firstAirDate:     json['first_air_date']   ?? '',
      lastAirDate:      json['last_air_date']    ?? '',
      status:           json['status']           ?? '',
      tagline:          json['tagline']          ?? '',
      inProduction:     json['in_production']    ?? false,
      numberOfSeasons:  json['number_of_seasons']  ?? 0,
      numberOfEpisodes: json['number_of_episodes'] ?? 0,
      episodeRunTime: List<int>.from(json['episode_run_time'] ?? []),
      type:             json['type']             ?? '',
      originalLanguage: json['original_language'] ?? '',
      genres: (json['genres'] as List? ?? [])
          .map((e) => MovieGenre.fromJson(e as Map<String, dynamic>))
          .toList(),
      spokenLanguages: (json['spoken_languages'] as List? ?? [])
          .map((e) => SpokenLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      networks: (json['networks'] as List? ?? [])
          .map((e) => TvNetwork.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Filter out season 0 (Specials) by default — shown separately if needed.
      seasons: (json['seasons'] as List? ?? [])
          .map((e) => SeasonInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      productionCompanies: (json['production_companies'] as List? ?? [])
          .map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── URL helpers ────────────────────────────────────────────────

  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropUrl =>
      backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w780$backdropPath' : '';

  // ── Computed display strings ────────────────────────────────────

  /// "45m" for single runtime, "40–45m" for a range, empty when unknown.
  String get formattedEpisodeRunTime {
    if (episodeRunTime.isEmpty) return '';
    final unique = episodeRunTime.toSet().toList()..sort();
    if (unique.length == 1) return '${unique.first}m';
    return '${unique.first}–${unique.last}m';
  }

  /// "07 Apr 2019" — same format as MovieDetailModel.formattedReleaseDate.
  String get formattedFirstAirDate => _formatDate(firstAirDate);

  /// "14 Mar 2023" — empty when not yet available.
  String get formattedLastAirDate => _formatDate(lastAirDate);

  /// "2019–2023" for ended shows, "2019–present" for ongoing, "2019" for
  /// single-year shows. Empty when firstAirDate is unavailable.
  String get airRange {
    if (firstAirDate.length < 4) return '';
    final startYear = firstAirDate.substring(0, 4);
    if (inProduction) return '$startYear–present';
    if (lastAirDate.length >= 4) {
      final endYear = lastAirDate.substring(0, 4);
      return startYear == endYear ? startYear : '$startYear–$endYear';
    }
    return startYear;
  }

  static String _formatDate(String date) {
    if (date.length < 10) return date;
    try {
      final dt = DateTime.parse(date);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day.toString().padLeft(2, '0')} '
          '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date;
    }
  }
}

// ── Nested models ─────────────────────────────────────────────────────────────

/// Broadcasting network (Netflix, HBO, BBC, etc.).
/// Similar shape to [ProductionCompany] but represents the distributor,
/// not the studio. Kept separate to allow different UI treatment.
class TvNetwork {
  final int id;
  final String name;
  final String logoPath;
  final String originCountry;

  const TvNetwork({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.originCountry,
  });

  factory TvNetwork.fromJson(Map<String, dynamic> json) => TvNetwork(
        id:            json['id']             ?? 0,
        name:          json['name']           ?? '',
        logoPath:      json['logo_path']      ?? '',
        originCountry: json['origin_country'] ?? '',
      );

  /// Logos from TMDB are mostly on transparent/white backgrounds.
  /// Wrap in a white container when displaying on dark backgrounds.
  String get fullLogoUrl =>
      logoPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w92$logoPath' : '';
}

/// Per-season metadata returned inside the TV detail payload.
/// Does NOT include individual episode data — fetch `/tv/{id}/season/{n}`
/// via [ApiConstants.tvSeason] if episode-level detail is needed.
class SeasonInfo {
  final int id;
  final String name;
  final int seasonNumber;
  final int episodeCount;
  final String posterPath;
  final String airDate;
  final String overview;

  const SeasonInfo({
    required this.id,
    required this.name,
    required this.seasonNumber,
    required this.episodeCount,
    required this.posterPath,
    required this.airDate,
    required this.overview,
  });

  factory SeasonInfo.fromJson(Map<String, dynamic> json) => SeasonInfo(
        id:           json['id']            ?? 0,
        name:         json['name']          ?? '',
        seasonNumber: json['season_number'] ?? 0,
        episodeCount: json['episode_count'] ?? 0,
        posterPath:   json['poster_path']   ?? '',
        airDate:      json['air_date']      ?? '',
        overview:     json['overview']      ?? '',
      );

  /// Poster at w185 — suitable for small season cards.
  /// Returns empty string when not available; caller should fall back to
  /// the parent show's poster.
  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';

  /// Four-digit year of the season premiere. Empty when airDate is unknown.
  String get airYear => airDate.length >= 4 ? airDate.substring(0, 4) : '';

  /// True for season 0, which TMDB uses for specials/extras.
  bool get isSpecials => seasonNumber == 0;
}
