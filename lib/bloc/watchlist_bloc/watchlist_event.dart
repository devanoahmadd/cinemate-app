import '../../data/models/watchlist_model.dart';

abstract class WatchlistEvent {}

/// Load the full watchlist from Firestore.
class WatchlistLoad extends WatchlistEvent {}

/// Add an item to the watchlist.
class WatchlistAdd extends WatchlistEvent {
  final WatchlistModel item;
  WatchlistAdd(this.item);
}

/// Remove an item by its docId.
class WatchlistRemove extends WatchlistEvent {
  final String docId;
  WatchlistRemove(this.docId);
}

/// Check if a single item is already saved (used by detail screens).
class WatchlistCheckItem extends WatchlistEvent {
  final String docId;
  WatchlistCheckItem(this.docId);
}
