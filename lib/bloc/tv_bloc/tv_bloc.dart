import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/movie_filter.dart';
import '../../data/models/tv_model.dart';
import '../../data/services/tv_service.dart';
import 'tv_event.dart';
import 'tv_state.dart';

class TvBloc extends Bloc<TvEvent, TvState> {
  final TvService _service;

  TvBloc(this._service) : super(TvInitial()) {
    on<TvFetchHome>(_onFetchHome);
    on<TvFetchPopular>(_onFetchPopular);
    on<TvFetchAiringToday>(_onFetchAiringToday);
    on<TvFetchOnTheAir>(_onFetchOnTheAir);
    on<TvFetchTopRated>(_onFetchTopRated);
    on<TvFetchGenres>(_onFetchGenres);
    on<TvFetchByGenre>(_onFetchByGenre);
    on<TvSearch>(_onSearch);
    on<TvClearSearch>(_onClearSearch);
    on<TvDiscover>(_onDiscover);
    on<TvFetchListPage>(_onFetchListPage);
  }

  Future<void> _onFetchHome(
    TvFetchHome event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      final results = await Future.wait([
        _service.getAiringToday(),
        _service.getPopular(),
      ]);
      emit(TvHomeLoaded(
        airingToday: results[0],
        popular:     results[1],
      ));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onFetchPopular(
    TvFetchPopular event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      emit(TvPopularLoaded(await _service.getPopular()));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onFetchAiringToday(
    TvFetchAiringToday event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      emit(TvAiringTodayLoaded(await _service.getAiringToday()));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onFetchOnTheAir(
    TvFetchOnTheAir event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      emit(TvOnTheAirLoaded(await _service.getOnTheAir()));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onFetchTopRated(
    TvFetchTopRated event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      emit(TvTopRatedLoaded(await _service.getTopRated()));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onFetchGenres(
    TvFetchGenres event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      emit(TvGenresLoaded(await _service.getGenres()));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onFetchByGenre(
    TvFetchByGenre event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      emit(TvGenreLoaded(await _service.getByGenre(event.genreId)));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onSearch(
    TvSearch event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      // Both searches run in parallel — total latency = max(title, actor).
      final fTitle = _service.searchTv(event.query);
      final fActor = _service.searchTvByActor(event.query);

      final titleShows  = await fTitle;
      final actorResult = await fActor;

      emit(TvSearchLoaded(
        titleShows: titleShows,
        actorShows: actorResult?.shows ?? [],
        actorName:  actorResult?.actorName,
      ));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  Future<void> _onClearSearch(
    TvClearSearch event,
    Emitter<TvState> emit,
  ) async {
    emit(TvInitial());
  }

  Future<void> _onDiscover(
    TvDiscover event,
    Emitter<TvState> emit,
  ) async {
    emit(TvLoading());
    try {
      final shows = await _service.discover(event.filter);
      emit(TvDiscoverLoaded(shows, event.filter));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }

  /// Handles [TvFetchListPage] — used exclusively by [TvListScreen].
  ///
  /// Emits [TvLoading] only for page 1 (initial load) so the grid stays
  /// visible during load-more fetches. The screen accumulates pages locally.
  Future<void> _onFetchListPage(
    TvFetchListPage event,
    Emitter<TvState> emit,
  ) async {
    if (event.page == 1) emit(TvLoading());

    try {
      final List<TvModel> shows;

      if (event.category.startsWith('genre_')) {
        final genreId = int.parse(event.category.split('_')[1]);
        if (event.sortOption != MovieSortOption.popular) {
          shows = await _service.discover(
            MovieFilter(sortBy: event.sortOption, genreIds: [genreId]),
            page: event.page,
          );
        } else {
          shows = await _service.getByGenre(genreId, page: event.page);
        }
      } else {
        shows = await switch (event.category) {
          'popular'      => _service.getPopular(page: event.page),
          'airing_today' => _service.getAiringToday(page: event.page),
          'on_the_air'   => _service.getOnTheAir(page: event.page),
          'top_rated'    => _service.getTopRated(page: event.page),
          _              => Future.value(<TvModel>[]),
        };
      }

      emit(TvListLoaded(
        shows:   shows,
        page:    event.page,
        // TMDB returns up to 20 per page — fewer means no more pages exist.
        hasMore: shows.length >= 20,
      ));
    } catch (e) {
      emit(TvError(e.toString()));
    }
  }
}
