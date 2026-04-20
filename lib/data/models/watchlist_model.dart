import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistModel {
  final int id;
  final String mediaType; // 'movie' | 'tv'
  final String title;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final DateTime addedAt;

  // movie-only
  final String? releaseDate;
  // tv-only
  final String? firstAirDate;

  WatchlistModel({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.addedAt,
    this.releaseDate,
    this.firstAirDate,
  });

  /// Firestore document ID — unique per media item, prevents duplicates.
  String get docId => '${mediaType}_$id';

  bool get isMovie => mediaType == 'movie';

  String get displayDate => isMovie
      ? (releaseDate?.substring(0, 4) ?? '')
      : (firstAirDate?.substring(0, 4) ?? '');

  factory WatchlistModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WatchlistModel(
      id:          d['id'] as int,
      mediaType:   d['mediaType'] as String,
      title:       d['title'] as String,
      posterUrl:   d['posterUrl'] as String,
      backdropUrl: d['backdropUrl'] as String,
      rating:      (d['rating'] as num).toDouble(),
      addedAt:     (d['addedAt'] as Timestamp).toDate(),
      releaseDate: d['releaseDate'] as String?,
      firstAirDate: d['firstAirDate'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id':          id,
        'mediaType':   mediaType,
        'title':       title,
        'posterUrl':   posterUrl,
        'backdropUrl': backdropUrl,
        'rating':      rating,
        'addedAt':     FieldValue.serverTimestamp(),
        if (releaseDate  != null) 'releaseDate':  releaseDate,
        if (firstAirDate != null) 'firstAirDate': firstAirDate,
      };
}
