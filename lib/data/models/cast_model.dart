/// Single cast member — from TMDB `/movie/{id}/credits` → `cast[]`.
class CastModel {
  final int id;
  final String name;
  final String character;
  final String profilePath;
  final int order;

  const CastModel({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
    required this.order,
  });

  factory CastModel.fromJson(Map<String, dynamic> json) => CastModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        character: json['character'] ?? '',
        profilePath: json['profile_path'] ?? '',
        order: json['order'] ?? 0,
      );

  /// W185 is the smallest TMDB size that still looks sharp in a 48px circle.
  String get fullProfileUrl =>
      profilePath.isNotEmpty ? 'https://image.tmdb.org/t/p/w185$profilePath' : '';

  /// Two-letter initials from the actor's name — fallback when no profile photo.
  /// "Chad Michael Collins" → "CM"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
