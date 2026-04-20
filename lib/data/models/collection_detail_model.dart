/// Full collection detail — from TMDB `/collection/{id}`.
/// Parts are sorted ascending by [releaseDate] (TMDB order is not guaranteed).
class CollectionDetailModel {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final List<CollectionPart> parts;

  const CollectionDetailModel({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.parts,
  });

  factory CollectionDetailModel.fromJson(Map<String, dynamic> json) {
    final rawParts = (json['parts'] as List? ?? [])
        .map((e) => CollectionPart.fromJson(e as Map<String, dynamic>))
        .toList();
    rawParts.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    return CollectionDetailModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      parts: rawParts,
    );
  }

  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropUrl =>
      backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w780$backdropPath' : '';
}

/// Single movie entry within a collection.
class CollectionPart {
  final int id;
  final String title;
  final String releaseDate;
  final String posterPath;
  final double voteAverage;
  final String overview;

  const CollectionPart({
    required this.id,
    required this.title,
    required this.releaseDate,
    required this.posterPath,
    required this.voteAverage,
    required this.overview,
  });

  factory CollectionPart.fromJson(Map<String, dynamic> json) => CollectionPart(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        releaseDate: json['release_date'] ?? '',
        posterPath: json['poster_path'] ?? '',
        voteAverage: (json['vote_average'] ?? 0).toDouble(),
        overview: json['overview'] ?? '',
      );

  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get year => releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
}
