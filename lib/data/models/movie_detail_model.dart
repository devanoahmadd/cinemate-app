/// Full movie detail — from TMDB endpoint `/movie/{id}`.
///
/// Distinct from [MovieModel] (which is used for list responses).
/// This model carries the richer payload returned by the detail endpoint:
/// runtime, tagline, adult flag, spoken languages, genres (full objects),
/// belongs_to_collection, budget, revenue, production companies, vote_count.
class MovieDetailModel {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String releaseDate;
  final int runtime;
  final String tagline;
  final bool adult;
  final String originalLanguage;
  final List<SpokenLanguage> spokenLanguages;
  final List<MovieGenre> genres;
  final CollectionInfo? belongsToCollection;
  final int budget;
  final int revenue;
  final List<ProductionCompany> productionCompanies;
  final String status;

  const MovieDetailModel({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.releaseDate,
    required this.runtime,
    required this.tagline,
    required this.adult,
    required this.originalLanguage,
    required this.spokenLanguages,
    required this.genres,
    this.belongsToCollection,
    required this.budget,
    required this.revenue,
    required this.productionCompanies,
    required this.status,
  });

  factory MovieDetailModel.fromJson(Map<String, dynamic> json) {
    return MovieDetailModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? '',
      runtime: json['runtime'] ?? 0,
      tagline: json['tagline'] ?? '',
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'] ?? '',
      spokenLanguages: (json['spoken_languages'] as List? ?? [])
          .map((e) => SpokenLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      genres: (json['genres'] as List? ?? [])
          .map((e) => MovieGenre.fromJson(e as Map<String, dynamic>))
          .toList(),
      belongsToCollection: json['belongs_to_collection'] != null
          ? CollectionInfo.fromJson(
              json['belongs_to_collection'] as Map<String, dynamic>)
          : null,
      budget: json['budget'] ?? 0,
      revenue: json['revenue'] ?? 0,
      productionCompanies: (json['production_companies'] as List? ?? [])
          .map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] ?? '',
    );
  }

  // ── URL helpers ────────────────────────────────────────────────

  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get fullBackdropUrl =>
      backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w780$backdropPath' : '';

  // ── Computed display strings ────────────────────────────────────

  /// "1h 42m" or "102m" when < 60, empty when runtime == 0.
  String get formattedRuntime {
    if (runtime <= 0) return '';
    final h = runtime ~/ 60;
    final m = runtime % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// "07 Apr 2026" — friendly date format without intl package.
  String get formattedReleaseDate {
    if (releaseDate.length < 10) return releaseDate;
    try {
      final dt = DateTime.parse(releaseDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day.toString().padLeft(2, '0')} '
          '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return releaseDate;
    }
  }

  /// "\$18,000,000" — empty string when budget == 0.
  String get formattedBudget {
    if (budget <= 0) return '';
    return '\$${_formatNumber(budget)}';
  }

  /// "\$41,200,000" — empty string when revenue == 0.
  String get formattedRevenue {
    if (revenue <= 0) return '';
    return '\$${_formatNumber(revenue)}';
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Nested models ────────────────────────────────────────────────────────

class MovieGenre {
  final int id;
  final String name;

  const MovieGenre({required this.id, required this.name});

  factory MovieGenre.fromJson(Map<String, dynamic> json) =>
      MovieGenre(id: json['id'] ?? 0, name: json['name'] ?? '');
}

class SpokenLanguage {
  final String iso;
  final String englishName;
  final String name;

  const SpokenLanguage({
    required this.iso,
    required this.englishName,
    required this.name,
  });

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) => SpokenLanguage(
        iso: json['iso_639_1'] ?? '',
        englishName: json['english_name'] ?? '',
        name: json['name'] ?? '',
      );
}

class CollectionInfo {
  final int id;
  final String name;
  final String posterPath;
  final String backdropPath;

  const CollectionInfo({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
  });

  factory CollectionInfo.fromJson(Map<String, dynamic> json) => CollectionInfo(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        posterPath: json['poster_path'] ?? '',
        backdropPath: json['backdrop_path'] ?? '',
      );

  String get fullPosterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';
}

class ProductionCompany {
  final int id;
  final String name;
  final String logoPath;
  final String originCountry;

  const ProductionCompany({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.originCountry,
  });

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      ProductionCompany(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        logoPath: json['logo_path'] ?? '',
        originCountry: json['origin_country'] ?? '',
      );

  String get fullLogoUrl =>
      logoPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w92$logoPath' : '';
}
