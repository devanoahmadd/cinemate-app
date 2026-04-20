import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/watchlist_service.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final WatchlistService _service;

  WatchlistBloc(this._service) : super(WatchlistInitial()) {
    on<WatchlistLoad>(_onLoad);
    on<WatchlistAdd>(_onAdd);
    on<WatchlistRemove>(_onRemove);
    on<WatchlistCheckItem>(_onCheckItem);
  }

  Future<void> _onLoad(
    WatchlistLoad event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(WatchlistLoading());
    try {
      final items = await _service.getWatchlist();
      emit(WatchlistLoaded(items));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> _onAdd(
    WatchlistAdd event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      await _service.add(event.item);
      // Emit status first so detail-screen listeners can update the bookmark icon.
      emit(WatchlistItemStatus(docId: event.item.docId, isSaved: true));
      // Always reload so profile tab stays fresh regardless of previous state.
      final items = await _service.getWatchlist();
      emit(WatchlistLoaded(items));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> _onRemove(
    WatchlistRemove event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      await _service.remove(event.docId);
      emit(WatchlistItemStatus(docId: event.docId, isSaved: false));
      final items = await _service.getWatchlist();
      emit(WatchlistLoaded(items));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> _onCheckItem(
    WatchlistCheckItem event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      final saved = await _service.isInWatchlist(event.docId);
      emit(WatchlistItemStatus(docId: event.docId, isSaved: saved));
    } catch (e) {
      emit(WatchlistItemStatus(docId: event.docId, isSaved: false));
    }
  }
}
