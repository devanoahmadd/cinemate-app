import '../../data/models/watchlist_model.dart';

abstract class WatchlistState {}

class WatchlistInitial extends WatchlistState {}

class WatchlistLoading extends WatchlistState {}

class WatchlistLoaded extends WatchlistState {
  final List<WatchlistModel> items;
  WatchlistLoaded(this.items);
}

/// Emitted while on a detail screen — carries the saved status of one item.
class WatchlistItemStatus extends WatchlistState {
  final String docId;
  final bool isSaved;
  WatchlistItemStatus({required this.docId, required this.isSaved});
}

class WatchlistError extends WatchlistState {
  final String message;
  WatchlistError(this.message);
}
