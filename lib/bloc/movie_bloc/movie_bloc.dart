import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/movie_service.dart';
import 'movie_event.dart';
import 'movie_state.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final MovieService _service;

  MovieBloc(this._service) : super(MovieInitial()) {
    on<MovieFetchHome>(_onFetchHome);
    on<MovieFetchPopular>(_onFetchPopular);
    on<MovieFetchNowPlaying>(_onFetchNowPlaying);
    on<MovieFetchTopRated>(_onFetchTopRated);
    on<MovieFetchUpcoming>(_onFetchUpcoming);
    on<MovieFetchGenres>(_onFetchGenres);
    on<MovieSearch>(_onSearch);
    on<MovieClearSearch>(_onClearSearch);
  }

  Future<void> _onFetchHome(
    MovieFetchHome event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final results = await Future.wait([
        _service.getNowPlaying(),
        _service.getPopular(),
      ]);
      emit(MovieHomeLoaded(
        nowPlaying: results[0],
        popular: results[1],
      ));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onFetchPopular(
    MovieFetchPopular event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.getPopular();
      emit(MoviePopularLoaded(movies));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onFetchNowPlaying(
    MovieFetchNowPlaying event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.getNowPlaying();
      emit(MovieNowPlayingLoaded(movies));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onFetchTopRated(
    MovieFetchTopRated event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.getTopRated();
      emit(MovieTopRatedLoaded(movies));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onFetchUpcoming(
    MovieFetchUpcoming event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.getUpcoming();
      emit(MovieUpcomingLoaded(movies));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onFetchGenres(
    MovieFetchGenres event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final genres = await _service.getGenres();
      emit(MovieGenresLoaded(genres));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onSearch(
    MovieSearch event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.searchMovies(event.query);
      emit(MovieSearchLoaded(movies));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  Future<void> _onClearSearch(
    MovieClearSearch event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieInitial());
  }
}