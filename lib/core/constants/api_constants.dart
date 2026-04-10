import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  static const String baseUrl = 'https://api.themoviedb.org/3';

  // Endpoints
  static const String nowPlaying = '/movie/now_playing';
  static const String popular = '/movie/popular';
  static const String topRated = '/movie/top_rated';
  static const String upcoming = '/movie/upcoming';
  static const String genres = '/genre/movie/list';
  static String movieDetails(int id) => '/movie/$id';
  static String searchMovie(String query) => '/search/movie?query=$query';
}