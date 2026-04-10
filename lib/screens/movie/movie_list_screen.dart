import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/movie_bloc/movie_bloc.dart';
import '../../bloc/movie_bloc/movie_event.dart';
import '../../bloc/movie_bloc/movie_state.dart';
import '../../core/routes/app_router.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/services/movie_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieListScreen extends StatefulWidget{
  final String category;
  const MovieListScreen({super.key, required this.category});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List<GenreModel> _genres = [];
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    _fetchByCategory(); // ✅ fix bug: tambah ()
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await MovieService().getGenres();
      if (mounted) setState(() => _genres = genres);
    } catch (_) {}
  }

  void _fetchByCategory() {
    final bloc = context.read<MovieBloc>();
    switch (widget.category) {
      case 'popular':
        bloc.add(MovieFetchPopular());
        break;
      case 'now_playing':
        bloc.add(MovieFetchNowPlaying());
        break;
      case 'top_rated':
        bloc.add(MovieFetchTopRated());
        break;
      case 'upcoming': // ✅ fix bug: lowercase
        bloc.add(MovieFetchUpcoming());
        break;
    }
  }

  String get _title {
    switch (widget.category) {
      case 'popular':     return 'Popular';
      case 'now_playing': return 'Now Playing';
      case 'top_rated':   return 'Top Rated';
      case 'upcoming':    return 'Upcoming';
      default:            return 'Film';
    }
  }

  // Filter Film berdasarkan genre yang dipilih
  List<MovieModel> _filterByGenre(List<MovieModel> movies) {
    if (_selectedGenreId == null) return movies;
    return movies
        .where((m) => m.genreIds.contains(_selectedGenreId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(_title,
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Genre filter chips
          if (_genres.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _genres.length + 1,
                itemBuilder: (context, i) {
                  //index 0 = "Semua"
                  final isAll = i == 0;
                  final genre = isAll ? null : _genres[i-1];
                  final isSelected = isAll
                      ? _selectedGenreId == null
                      : _selectedGenreId == genre?.id;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedGenreId = genre?.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE94560)
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE94560)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        isAll ? 'Semua' : genre!.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white60,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Movie Grid
          Expanded(
            child: BlocBuilder<MovieBloc, MovieState>(
              builder: (context, state) {
                if (state is MovieLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFE94560)));
                }

                List<MovieModel> movies = [];
                if (state is MoviePopularLoaded)    movies = state.movies;
                if (state is MovieNowPlayingLoaded) movies = state.movies;
                if (state is MovieTopRatedLoaded)   movies = state.movies;
                if (state is MovieUpcomingLoaded)   movies = state.movies;

                // Terapkan Filter Genre

              final filtered = _filterByGenre(movies);
              
              if (filtered.isEmpty) {
                  return const Center(
                      child: Text('Tidak ada film',
                          style:
                              TextStyle(color: Colors.white54)));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                ),
                itemBuilder: (context, i) {
                  final movie = filtered[i];
                  return GestureDetector(
                    onTap: () => context.push(
                      AppRouter.movieDetail,
                        extra: {
                          'id': movie.id,
                          'title': movie.title,
                          'overview': movie.overview,
                          'posterUrl': movie.fullPosterUrl,
                          'backdropUrl': movie.fullBackdropUrl,
                          'rating': movie.voteAverage,
                          'releaseDate': movie.releaseDate,
                        },
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: movie.fullPosterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (_, __) =>
                                  Container(color: Colors.white12),
                              errorWidget: (_, __, ___) =>
                                  Container(
                                      color: Colors.white12,
                                      child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.white30)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11),
                              ),
                            ],
                        )
                      ],
                    ),
                  );
                });
              }))
        ],
      ),
    );
  }
}