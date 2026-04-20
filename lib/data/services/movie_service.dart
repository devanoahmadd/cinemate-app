import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../models/movie_detail_model.dart';
import '../models/collection_detail_model.dart';
import '../models/cast_model.dart';
import '../models/review_model.dart';
import '../models/video_model.dart';
import '../models/watch_provider_model.dart';
import '../models/genre_model.dart';
import '../models/movie_filter.dart';
import '../../core/constants/api_constants.dart';

class MovieService {
  late final Dio _dio;

  MovieService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Authorization' : 'Bearer ${ApiConstants.accessToken}',
        'accept': 'application/json',
      },
    ));
  }

  // Fetch List helper
  Future<List<MovieModel>> _fetchMovies(String endpoint) async {
    final response = await _dio.get(endpoint);
    final result = response.data['results'] as List;
    return result.map((e) => MovieModel.fromJson(e)).toList();
  }

  Future<List<MovieModel>> getNowPlaying({int page = 1}) =>
      _fetchMovies(ApiConstants.nowPlaying(page: page));

  Future<List<MovieModel>> getPopular({int page = 1}) =>
      _fetchMovies(ApiConstants.popular(page: page));

  Future<List<MovieModel>> getTopRated({int page = 1}) =>
      _fetchMovies(ApiConstants.topRated(page: page));

  Future<List<MovieModel>> getUpcoming({int page = 1}) =>
      _fetchMovies(ApiConstants.upcoming(page: page));

  Future<List<MovieModel>> searchMovies(String query)
      => _fetchMovies(ApiConstants.searchMovie(query));

  /// Fallback: search by actor name.
  /// Returns the actor's credited movies sorted by rating, or null if no
  /// matching person was found on TMDB.
  Future<({List<MovieModel> movies, String actorName})?> searchMoviesByActor(
    String query,
  ) async {
    final personResp = await _dio.get(ApiConstants.searchPerson(query));
    final people = personResp.data['results'] as List? ?? [];
    if (people.isEmpty) return null;

    final person    = people.first as Map<String, dynamic>;
    final personId  = person['id'] as int;
    final actorName = person['name'] as String? ?? query;

    final creditsResp = await _dio.get(ApiConstants.personMovieCredits(personId));
    final cast        = creditsResp.data['cast'] as List? ?? [];

    final movies = cast
        .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
        .where((m) => m.posterPath.isNotEmpty && m.voteAverage > 0)
        .toList()
      ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return (movies: movies, actorName: actorName);
  }

  Future<List<MovieModel>> getByGenre(int genreId, {int page = 1})
      => _fetchMovies(ApiConstants.discoverByGenre(genreId, page: page));

  Future<List<GenreModel>> getGenres() async {
    final response = await _dio.get(ApiConstants.genres);
    final result = response.data['genres'] as List;
    return result.map((e) => GenreModel.fromJson(e)).toList();
  }

  Future<MovieModel> getMovieDetail(int id) async {
    final response = await _dio.get(ApiConstants.movieDetails(id));
    return MovieModel.fromJson(response.data);
  }

  /// Full detail payload — richer than [getMovieDetail].
  /// Returns [MovieDetailModel] with runtime, tagline, adult flag, genres,
  /// collection, budget, revenue, production companies, spoken languages.
  Future<MovieDetailModel> getMovieDetailFull(int id) async {
    final response = await _dio.get(ApiConstants.movieDetails(id));
    return MovieDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Full cast list — ordered by `order` field, no cap (caller truncates for preview).
  Future<List<CastModel>> getMovieCredits(int id) async {
    final response = await _dio.get(ApiConstants.movieCredits(id));
    final cast = response.data['cast'] as List? ?? [];
    return cast
        .map((e) => CastModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// User reviews — paged (20 per page).
  Future<List<ReviewModel>> getMovieReviews(int id, {int page = 1}) async {
    final response = await _dio.get(ApiConstants.movieReviews(id, page: page));
    final results = response.data['results'] as List? ?? [];
    return results
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Similar movies — paged (20 per page).
  Future<List<MovieModel>> getMovieSimilar(int id, {int page = 1}) =>
      _fetchMovies(ApiConstants.movieSimilar(id, page: page));

  /// Recommended movies — paged (20 per page).
  Future<List<MovieModel>> getMovieRecommendations(int id, {int page = 1}) =>
      _fetchMovies(ApiConstants.movieRecommendations(id, page: page));

  /// Full collection detail including all parts, sorted by release date.
  Future<CollectionDetailModel> getCollectionDetails(int id) async {
    final response = await _dio.get(ApiConstants.collectionDetails(id));
    return CollectionDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// YouTube videos (trailers, teasers) — filtered to YouTube only.
  Future<List<VideoModel>> getMovieVideos(int id) async {
    final response = await _dio.get(ApiConstants.movieVideos(id));
    final results = response.data['results'] as List? ?? [];
    return results
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .where((v) => v.isYouTube)
        .toList();
  }

  /// Streaming/buy providers for locale [locale], fallback to "US".
  Future<List<WatchProviderModel>> getMovieWatchProviders(
    int id, {
    String locale = 'ID',
  }) async {
    final response = await _dio.get(ApiConstants.movieWatchProviders(id));
    return WatchProviderModel.parseFromResponse(
      response.data as Map<String, dynamic>,
      locale: locale,
    );
  }

  /// Fetches movies using TMDB Discover or Trending endpoint based on [filter].
  /// - [MovieSortOption.trending] → /trending/movie/week (genre filtered client-side)
  /// - All other options          → /discover/movie?sort_by=...&with_genres=...
  Future<List<MovieModel>> discover(MovieFilter filter, {int page = 1}) {
    if (filter.sortBy == MovieSortOption.trending) {
      // Trending endpoint does not support pagination — always page 1.
      return _fetchMovies(ApiConstants.trending);
    }
    return _fetchMovies(ApiConstants.discover(
      sortBy: filter.sortBy.apiValue,
      genreIds: filter.genreIds,
      page: page,
    ));
  }
}