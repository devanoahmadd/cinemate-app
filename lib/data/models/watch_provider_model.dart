/// A single streaming/buy/rent provider entry.
///
/// Source: TMDB `/movie/{id}/watch/providers`
/// Response path: `results.ID.flatrate[]` (streaming)
///               or `results.ID.buy[]` / `results.ID.rent[]`
///
/// Usage: fetch providers for locale "ID", fallback to "US" if absent.
class WatchProviderModel {
  final int providerId;
  final String providerName;
  final String logoPath;
  final int displayPriority;

  const WatchProviderModel({
    required this.providerId,
    required this.providerName,
    required this.logoPath,
    required this.displayPriority,
  });

  factory WatchProviderModel.fromJson(Map<String, dynamic> json) =>
      WatchProviderModel(
        providerId: json['provider_id'] ?? 0,
        providerName: json['provider_name'] ?? '',
        logoPath: json['logo_path'] ?? '',
        displayPriority: json['display_priority'] ?? 99,
      );

  /// W92 gives a crisp 24–32px logo at 2×.
  String get fullLogoUrl =>
      logoPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w92$logoPath' : '';

  /// Parse a raw watch-providers API response and return the provider list
  /// for locale [locale] → flatrate first, then buy, then rent.
  /// Falls back to "US" if [locale] is absent. Returns empty list if neither found.
  static List<WatchProviderModel> parseFromResponse(
    Map<String, dynamic> json, {
    String locale = 'ID',
  }) {
    final results = json['results'] as Map<String, dynamic>? ?? {};
    final localeData = (results[locale] ?? results['US']) as Map<String, dynamic>?;
    if (localeData == null) return [];

    // Prefer flatrate (streaming), fallback to buy, then rent
    final raw = (localeData['flatrate'] ??
        localeData['buy'] ??
        localeData['rent']) as List?;
    if (raw == null) return [];

    return raw
        .map((e) => WatchProviderModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
  }
}
