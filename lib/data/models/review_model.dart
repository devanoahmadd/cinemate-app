/// Single user review — from TMDB `/movie/{id}/reviews` → `results[]`.
class ReviewModel {
  final String id;
  final String author;
  final double? rating;   // author_details.rating — nullable (0–10 scale)
  final String content;
  final String createdAt; // ISO-8601 string from API

  const ReviewModel({
    required this.id,
    required this.author,
    this.rating,
    required this.content,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final details = json['author_details'] as Map<String, dynamic>? ?? {};
    final rawRating = details['rating'];
    return ReviewModel(
      id: json['id'] ?? '',
      author: json['author'] ?? '',
      rating: rawRating != null ? (rawRating as num).toDouble() : null,
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Two-letter initials for the avatar placeholder.
  /// "Brett Pascoe" → "BP", "MSB" → "MS"
  String get initials {
    final parts = author.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// "5 Jul 2018" — parsed from ISO-8601 without intl package.
  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    }
  }
}
