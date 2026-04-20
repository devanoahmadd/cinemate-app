import 'package:dio/dio.dart';
import '../models/tv_model.dart';
import '../models/tv_detail_model.dart';
import '../models/cast_model.dart';
import '../models/review_model.dart';
import '../models/watch_provider_model.dart';
import '../models/genre_model.dart';
import '../models/video_model.dart';
import '../models/movie_filter.dart';
import '../../core/constants/api_constants.dart';

class TvService {
  late final Dio _dio;

  TvService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Authorization': 'Bearer ${ApiConstants.accessToken}',
        'accept': 'application/json',
      },
    ));
  }

  // ── Private fetch helper ───────────────────────────────────────

  Future<List<TvModel>> _fetchShows(String endpoint) async {
    final response = await _dio.get(endpoint);
    final result = response.data['results'] as List;
    return result.map((e) => TvModel.fromJson(e)).toList();
  }

  // ── List endpoints ─────────────────────────────────────────────

  /// Episodes airing today — equivalent of movie "now_playing".
  Future<List<TvModel>> getAiringToday({int page = 1}) =>
      _fetchShows(ApiConstants.tvAiringToday(page: page));

  /// Shows currently airing within the next 7 days.
  Future<List<TvModel>> getOnTheAir({int page = 1}) =>
      _fetchShows(ApiConstants.tvOnTheAir(page: page));

  Future<List<TvModel>> getPopular({int page = 1}) =>
      _fetchShows(ApiConstants.tvPopular(page: page));

  Future<List<TvModel>> getTopRated({int page = 1}) =>
      _fetchShows(ApiConstants.tvTopRated(page: page));

  Future<List<TvModel>> getTrending() =>
      _fetchShows(ApiConstants.tvTrending);

  Future<List<TvModel>> searchTv(String query) =>
      _fetchShows(ApiConstants.searchTv(query));

  /// Fallback: search by actor name.
  /// Returns the actor's credited TV shows sorted by rating, or null if no
  /// matching person was found on TMDB.
  Future<({List<TvModel> shows, String actorName})?> searchTvByActor(
    String query,
  ) async {
    final personResp = await _dio.get(ApiConstants.searchPerson(query));
    final people = personResp.data['results'] as List? ?? [];
    if (people.isEmpty) return null;

    final person    = people.first as Map<String, dynamic>;
    final personId  = person['id'] as int;
    final actorName = person['name'] as String? ?? query;

    final creditsResp = await _dio.get(ApiConstants.personTvCredits(personId));
    final cast        = creditsResp.data['cast'] as List? ?? [];

    final shows = cast
        .map((e) => TvModel.fromJson(e as Map<String, dynamic>))
        .where((s) => s.posterPath.isNotEmpty && s.voteAverage > 0)
        .toList()
      ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return (shows: shows, actorName: actorName);
  }

  Future<List<TvModel>> getByGenre(int genreId, {int page = 1}) =>
      _fetchShows(ApiConstants.tvDiscoverByGenre(genreId, page: page));

  /// TV genre list — IDs differ from movie genres; do not mix them.
  Future<List<GenreModel>> getGenres() async {
    final response = await _dio.get(ApiConstants.tvGenres);
    final result = response.data['genres'] as List;
    return result.map((e) => GenreModel.fromJson(e)).toList();
  }

  // ── Detail endpoints ───────────────────────────────────────────

  /// Full TV show detail with seasons, networks, genres, etc.
  Future<TvDetailModel> getTvDetailFull(int id) async {
    final response = await _dio.get(ApiConstants.tvDetails(id));
    return TvDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Top-billed cast (max 20 entries, ordered by TMDB `order` field).
  /// Reuses [CastModel] — the credits payload shape is identical for TV.
  Future<List<CastModel>> getTvCredits(int id) async {
    final response = await _dio.get(ApiConstants.tvCredits(id));
    final cast = response.data['cast'] as List? ?? [];
    return cast
        .map((e) => CastModel.fromJson(e as Map<String, dynamic>))
        .take(20)
        .toList();
  }

  /// User reviews — first page (up to 20 reviews).
  /// Reuses [ReviewModel] — the reviews payload shape is identical for TV.
  Future<List<ReviewModel>> getTvReviews(int id) async {
    final response = await _dio.get(ApiConstants.tvReviews(id));
    final results = response.data['results'] as List? ?? [];
    return results
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Similar shows — first page of results.
  Future<List<TvModel>> getTvSimilar(int id) =>
      _fetchShows(ApiConstants.tvSimilar(id));

  /// Recommended shows — first page of results.
  Future<List<TvModel>> getTvRecommendations(int id) =>
      _fetchShows(ApiConstants.tvRecommendations(id));

  /// YouTube videos (trailers, teasers) — filtered to YouTube only.
  Future<List<VideoModel>> getTvVideos(int id) async {
    final response = await _dio.get(ApiConstants.tvVideos(id));
    final results = response.data['results'] as List? ?? [];
    return results
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .where((v) => v.isYouTube)
        .toList();
  }

  /// Streaming/buy providers for [locale], fallback to "US".
  /// Reuses [WatchProviderModel] — the watch providers payload is identical.
  Future<List<WatchProviderModel>> getTvWatchProviders(
    int id, {
    String locale = 'ID',
  }) async {
    final response = await _dio.get(ApiConstants.tvWatchProviders(id));
    return WatchProviderModel.parseFromResponse(
      response.data as Map<String, dynamic>,
      locale: locale,
    );
  }

  // ── Discover ───────────────────────────────────────────────────

  /// Fetches TV shows using TMDB Discover or Trending endpoint based on [filter].
  ///
  /// - [MovieSortOption.trending] → /trending/tv/week (genre filtered client-side)
  /// - [MovieSortOption.latest]   → uses `first_air_date.desc` (not `release_date.desc`)
  /// - [MovieSortOption.longest]  → TV has no runtime sort; falls back to `popularity.desc`
  /// - All other options          → /discover/tv?sort_by=...&with_genres=...
  ///
  /// Reuses [MovieFilter] and [MovieSortOption] — the filter contract is
  /// identical for TV; only the target endpoint differs.
  Future<List<TvModel>> discover(MovieFilter filter, {int page = 1}) {
    if (filter.sortBy == MovieSortOption.trending) {
      // Trending endpoint does not support pagination — always page 1.
      return _fetchShows(ApiConstants.tvTrending);
    }

    // Map sort options that have TV-specific API values.
    final String sortBy;
    switch (filter.sortBy) {
      case MovieSortOption.latest:
        sortBy = 'first_air_date.desc'; // TV uses first_air_date, not release_date
        break;
      case MovieSortOption.longest:
        sortBy = 'popularity.desc';     // TV has no episode_run_time sort on TMDB
        break;
      default:
        sortBy = filter.sortBy.apiValue;
    }

    return _fetchShows(ApiConstants.discoverTv(
      sortBy: sortBy,
      genreIds: filter.genreIds,
      page: page,
    ));
  }
}
