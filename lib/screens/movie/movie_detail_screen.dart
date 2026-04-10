import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieDetailScreen extends StatelessWidget {
  final Map<String, dynamic> movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: movie['backdropUrl'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => 
                        Container(color: Colors.white12),
                    errorWidget: (_, __, ___) => 
                        Container(color: Colors.white12),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                          const Color(0xFF1A1A2E),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Title
                  Text(movie['title'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  //Rating & Date
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber,
                          size: 18),
                      const SizedBox(width: 4),
                      Text(
                        (movie['rating'] as double).toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text(movie['releaseDate'] ?? '', 
                          style: const TextStyle(
                            color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Sinopsis',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    movie['overview']?.isNotEmpty == true
                        ? movie['overview']
                        : 'Sinopsis tidak tersedia. ',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.6),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}