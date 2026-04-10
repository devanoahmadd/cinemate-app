import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../../bloc/movie_bloc/movie_bloc.dart';
import '../../../bloc/movie_bloc/movie_event.dart';
import '../../../bloc/movie_bloc/movie_state.dart';
import '../../../core/routes/app_router.dart';
import '../../../data/models/movie_model.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasQuery = false;
  Timer? _debounce;

   @override
  void initState() {
    super.initState();
    // Auto-focus saat tab dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _debounce?.cancel();
      setState(() => _hasQuery = false);
      context.read<MovieBloc>().add(MovieClearSearch());
      return;
    }
    setState(() => _hasQuery = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      context.read<MovieBloc>().add(MovieSearch(trimmed));
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearch('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Header
            const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            //  Search Bar
            Padding(
              padding: const EdgeInsetsGeometry.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari judul, aktor, genre...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  suffixIcon: _hasQuery
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE94560),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            //  Hasil
            Expanded(
              child: BlocBuilder<MovieBloc, MovieState>(
                builder: (context, state) {
                  if (!_hasQuery) {
                    return _buildPlaceholder();
                  }
                  if (state is MovieLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE94560),
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (state is MovieSearchLoaded) {
                    if (state.movies.isEmpty) {
                      return _buildEmptyResult();
                    }
                    return _buildSearchResults(state.movies);
                  }
                  if (state is MovieError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE94560),
                      strokeWidth: 2
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  //  PLACEHOLDER
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_filter_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Cari film favoritmu',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ketik judul film di kolom pencarian',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Hasil kosong
  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 12),
          Text(
            'Film tidak ditemukan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci lain',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  //  Hasil Saerch (vertical list)
  Widget _buildSearchResults(List<MovieModel> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            '${movies.length} hasil ditemukan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final movie = movies[i];
              return _SearchResultItem(
                movie: movie,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

// Hasil Pecnarina Item
class _SearchResultItem extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;

  const _SearchResultItem({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: movie.fullPosterUrl,
                width: 52,
                height: 74,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 52,
                  height: 74,
                  color: Colors.white12,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 52,
                  height: 74,
                  color: Colors.white12,
                  child: const Icon(Icons.broken_image,
                      color: Colors.white30, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFD93D), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (movie.releaseDate.length >= 4) ...[
                        const SizedBox(width: 10),
                        Text(
                          movie.releaseDate.substring(0, 4),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (movie.overview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}