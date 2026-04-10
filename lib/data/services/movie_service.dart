import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../models/genre_model.dart';
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

  Future<List<MovieModel>> getNowPlaying() async {
    return _fetchMovies(ApiConstants.nowPlaying);
  }

  Future<List<MovieModel>> getPopular() async {
    return _fetchMovies(ApiConstants.popular);
  }

  Future<List<MovieModel>> getTopRated() async {
    return _fetchMovies(ApiConstants.topRated);
  }

  Future<List<MovieModel>> getUpcoming() async {
    return _fetchMovies(ApiConstants.upcoming);
  }

  Future<List<MovieModel>> searchMovies(String query) 
  => _fetchMovies(ApiConstants.searchMovie(query));

  Future<List<GenreModel>> getGenres() async {
    final response = await _dio.get(ApiConstants.genres);
    final result = response.data['genres'] as List;
    return result.map((e) => GenreModel.fromJson(e)).toList();
  }

  Future<MovieModel> getMovieDetail(int id) async {
    final response = await _dio.get(ApiConstants.movieDetails(id));
    return MovieModel.fromJson(response.data);
  }
}