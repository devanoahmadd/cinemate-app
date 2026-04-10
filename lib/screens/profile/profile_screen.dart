import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';
import '../../bloc/auth_bloc/auth_event.dart';
import '../../bloc/auth_bloc/auth_state.dart';
import '../../core/routes/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Profile',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFE94560),
              child: Text(
                (user.email?.substring(0, 1) ?? 'U').toUpperCase(),
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.email ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('UID: ${user.uid.substring(0, 8)}...',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 40),

            // Info Cards
            _infoTile(Icons.email_outlined, 'Email', user.email ?? '-'),
            const SizedBox(height: 12),
            _infoTile(Icons.verified_user_outlined, 'Status', 
                user.emailVerified ? 'Terverifikasi' : 'Belum Terverifikasi'),
            const SizedBox(height: 12),
            _infoTile(Icons.movie_filter_outlined, 'Aplikasi', 'Cinemate v1.0.0'),
            const SizedBox(height: 12),
            _infoTile(Icons.api_outlined, 'Data Source', 'TMDB API'),

            const Spacer(),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go(AppRouter.login);
                },
                icon: const Icon(Icons.logout, color: Color(0xFFE94560)), 
                label: const Text('Keluar Akun',
                    style: TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE94560)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16)
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE94560), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, 
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
              Text(value, 
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}