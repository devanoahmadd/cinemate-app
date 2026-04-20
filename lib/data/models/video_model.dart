/// Single video entry — from TMDB `/movie/{id}/videos` or `/tv/{id}/videos`.
class VideoModel {
  final String key;
  final String site;
  final String type;
  final String name;
  final bool official;

  const VideoModel({
    required this.key,
    required this.site,
    required this.type,
    required this.name,
    required this.official,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
        key:      json['key']      as String? ?? '',
        site:     json['site']     as String? ?? '',
        type:     json['type']     as String? ?? '',
        name:     json['name']     as String? ?? '',
        official: json['official'] as bool?   ?? false,
      );

  bool get isYouTube => site == 'YouTube' && key.isNotEmpty;

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';
}

/// Picks the best trailer from a list using priority order:
///   1. Official YouTube Trailer
///   2. Unofficial YouTube Trailer
///   3. Official YouTube Teaser
///   4. Any YouTube video
/// Returns null when the list is empty or contains no YouTube videos.
VideoModel? pickBestTrailer(List<VideoModel> videos) {
  final yt = videos.where((v) => v.isYouTube).toList();
  if (yt.isEmpty) return null;

  for (final criteria in [
    (v: yt, official: true,  type: 'Trailer'),
    (v: yt, official: false, type: 'Trailer'),
    (v: yt, official: true,  type: 'Teaser'),
    (v: yt, official: false, type: 'Teaser'),
  ]) {
    final match = criteria.v.where((v) =>
        v.official == criteria.official && v.type == criteria.type);
    if (match.isNotEmpty) return match.first;
  }
  return yt.first;
}
