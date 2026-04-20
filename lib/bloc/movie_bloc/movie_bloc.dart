import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/movie_filter.dart';
import '../../data/models/movie_model.dart';
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
    on<MovieFetchByGenre>(_onFetchByGenre);
    on<MovieSearch>(_onSearch);
    on<MovieClearSearch>(_onClearSearch);
    on<MovieDiscover>(_onDiscover);
    on<MovieFetchListPage>(_onFetchListPage);
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

  Future<void> _onFetchByGenre(
    MovieFetchByGenre event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.getByGenre(event.genreId);
      emit(MovieGenreLoaded(movies));
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
      // Both searches run in parallel — total latency = max(title, actor).
      final fTitle = _service.searchMovies(event.query);
      final fActor = _service.searchMoviesByActor(event.query);

      final titleMovies = await fTitle;
      final actorResult = await fActor;

      emit(MovieSearchLoaded(
        titleMovies: titleMovies,
        actorMovies: actorResult?.movies ?? [],
        actorName:   actorResult?.actorName,
      ));
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

  Future<void> _onDiscover(
    MovieDiscover event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await _service.discover(event.filter);
      emit(MovieDiscoverLoaded(movies, event.filter));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }

  /// Maps a category string to the [MovieSortOption] that best represents it
  /// when a genre chip is selected (server-side discover fallback).
  MovieSortOption _categorySort(String category) => switch (category) {
    'top_rated'   => MovieSortOption.topRated,
    'upcoming'    => MovieSortOption.latest,
    _             => MovieSortOption.popular, // popular, now_playing
  };

  /// Handles [MovieFetchListPage] — used exclusively by [MovieListScreen].
  ///
  /// Emits [MovieLoading] only for page 1 (initial load) so the grid stays
  /// visible during load-more fetches. The screen accumulates pages locally.
  ///
  /// When [event.genreFilter] is set on a non-genre category page, the fetch
  /// switches to /discover with the category-appropriate sort + the genre ID,
  /// returning accurate server-side results across all pages.
  Future<void> _onFetchListPage(
    MovieFetchListPage event,
    Emitter<MovieState> emit,
  ) async {
    if (event.page == 1) emit(MovieLoading());

    try {
      final List<MovieModel> movies;

      if (event.category.startsWith('genre_')) {
        // Genre page — existing sort-sheet logic unchanged.
        final genreId = int.parse(event.category.split('_')[1]);
        if (event.sortOption != MovieSortOption.popular) {
          movies = await _service.discover(
            MovieFilter(sortBy: event.sortOption, genreIds: [genreId]),
            page: event.page,
          );
        } else {
          movies = await _service.getByGenre(genreId, page: event.page);
        }
      } else if (event.genreFilter != null) {
        // Category page + genre chip selected → server-side discover.
        // Uses the category's natural sort so results stay contextually
        // relevant (e.g. top_rated + Documentary = top-rated documentaries).
        movies = await _service.discover(
          MovieFilter(
            sortBy: _categorySort(event.category),
            genreIds: [event.genreFilter!],
          ),
          page: event.page,
        );
      } else {
        // Category page, no genre filter — standard endpoint.
        movies = await switch (event.category) {
          'popular'     => _service.getPopular(page: event.page),
          'now_playing' => _service.getNowPlaying(page: event.page),
          'top_rated'   => _service.getTopRated(page: event.page),
          'upcoming'    => _service.getUpcoming(page: event.page),
          _             => Future.value(<MovieModel>[]),
        };
      }

      emit(MovieListLoaded(
        movies: movies,
        page: event.page,
        // TMDB returns up to 20 per page — fewer means no more pages exist.
        hasMore: movies.length >= 20,
      ));
    } catch (e) {
      emit(MovieError(e.toString()));
    }
  }
}