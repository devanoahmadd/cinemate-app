import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  static const String baseUrl = 'https://api.themoviedb.org/3';

  // ════════════════════════════════════════════════════════════════
  // MOVIE ENDPOINTS
  // ════════════════════════════════════════════════════════════════

  // ── Movie list — all accept an optional [page] (default: 1) ────
  static String nowPlaying({int page = 1}) => '/movie/now_playing?page=$page';
  static String popular({int page = 1})    => '/movie/popular?page=$page';
  static String topRated({int page = 1})   => '/movie/top_rated?page=$page';
  static String upcoming({int page = 1})   => '/movie/upcoming?page=$page';

  /// Weekly trending movies — separate endpoint, not a discover sort.
  static const String trending = '/trending/movie/week';

  static const String genres = '/genre/movie/list';

  static String searchMovie(String query) => '/search/movie?query=$query';

  // ── Person / actor search ───────────────────────────────────────
  static String searchPerson(String query)      => '/search/person?query=$query';
  static String personMovieCredits(int id)      => '/person/$id/movie_credits';
  static String personTvCredits(int id)         => '/person/$id/tv_credits';

  static String discoverByGenre(int genreId, {int page = 1}) =>
      '/discover/movie?with_genres=$genreId&sort_by=popularity.desc&page=$page';

  // ── Movie detail ────────────────────────────────────────────────
  static String movieDetails(int id)         => '/movie/$id';
  static String movieCredits(int id)         => '/movie/$id/credits';
  static String movieReviews(int id, {int page = 1})         => '/movie/$id/reviews?page=$page';
  static String movieSimilar(int id, {int page = 1})         => '/movie/$id/similar?page=$page';
  static String movieRecommendations(int id, {int page = 1}) => '/movie/$id/recommendations?page=$page';
  static String collectionDetails(int id)                    => '/collection/$id';
  static String movieWatchProviders(int id)  => '/movie/$id/watch/providers';
  static String movieVideos(int id)          => '/movie/$id/videos';

  /// Discover endpoint with sort + optional genre filter + page.
  /// For top_rated, a minimum vote count guard is added automatically
  /// to prevent obscure films with a single 10/10 from ranking first.
  /// Multi-genre: [genreIds] are joined with commas → TMDB AND-logic.
  /// e.g. [28, 18] → &with_genres=28,18 (must match ALL genres).
  static String discover({
    required String sortBy,
    List<int> genreIds = const [],
    int page = 1,
  }) {
    final buf = StringBuffer('/discover/movie?sort_by=$sortBy');
    if (sortBy == 'vote_average.desc') buf.write('&vote_count.gte=200');
    if (genreIds.isNotEmpty) buf.write('&with_genres=${genreIds.join(',')}');
    buf.write('&page=$page');
    return buf.toString();
  }

  // ════════════════════════════════════════════════════════════════
  // TV ENDPOINTS
  // ════════════════════════════════════════════════════════════════

  // ── TV list — all accept an optional [page] (default: 1) ───────
  /// Shows airing new episodes today.
  static String tvAiringToday({int page = 1}) => '/tv/airing_today?page=$page';

  /// Shows currently airing (within the next 7 days).
  static String tvOnTheAir({int page = 1})    => '/tv/on_the_air?page=$page';

  static String tvPopular({int page = 1})     => '/tv/popular?page=$page';
  static String tvTopRated({int page = 1})    => '/tv/top_rated?page=$page';

  /// Weekly trending TV shows — separate endpoint, not a discover sort.
  static const String tvTrending = '/trending/tv/week';

  /// TV genre list — IDs are different from movie genre IDs.
  static const String tvGenres = '/genre/tv/list';

  static String searchTv(String query) => '/search/tv?query=$query';

  static String tvDiscoverByGenre(int genreId, {int page = 1}) =>
      '/discover/tv?with_genres=$genreId&sort_by=popularity.desc&page=$page';

  // ── TV detail ────────────────────────────────────────────────────
  static String tvDetails(int id)         => '/tv/$id';
  static String tvCredits(int id)         => '/tv/$id/credits';
  static String tvReviews(int id)         => '/tv/$id/reviews';
  static String tvSimilar(int id)         => '/tv/$id/similar';
  static String tvRecommendations(int id) => '/tv/$id/recommendations';
  static String tvWatchProviders(int id)  => '/tv/$id/watch/providers';
  static String tvVideos(int id)          => '/tv/$id/videos';

  /// Season detail — returns episode list, air dates, etc.
  static String tvSeason(int id, int seasonNumber) =>
      '/tv/$id/season/$seasonNumber';

  /// Discover TV with sort + optional genre filter + page.
  /// Uses vote_count.gte=50 for top_rated (lower threshold than movies —
  /// TV shows typically have fewer votes than blockbuster films).
  static String discoverTv({
    required String sortBy,
    List<int> genreIds = const [],
    int page = 1,
  }) {
    final buf = StringBuffer('/discover/tv?sort_by=$sortBy');
    if (sortBy == 'vote_average.desc') buf.write('&vote_count.gte=50');
    if (genreIds.isNotEmpty) buf.write('&with_genres=${genreIds.join(',')}');
    buf.write('&page=$page');
    return buf.toString();
  }
}