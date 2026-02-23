import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_provider.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: const AssetImage('assets/images/avatar.png'),
                    onBackgroundImageError: (_, __) {},
                    child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ).animate().scale(),

            const SizedBox(height: 16),

            Text(
              user.name,
              style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 100.ms),

            Text(
              user.email,
              style: context.textStyles.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Cargo: ${user.roleName}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            // Menu Options
            if (user.roleName == 'admin') 
              _ProfileMenuItem(
                icon: Icons.admin_panel_settings,
                title: 'Painel Admin',
                onTap: () => context.push('/admin/console'),
              ).animate().slideX(delay: 200.ms),

            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Dados da Conta',
              onTap: () => context.push('/profile/account'),
            ).animate().slideX(delay: 250.ms),
            
            _ProfileMenuItem(
              icon: Icons.analytics_outlined,
              title: 'Central de Atividade',
              onTap: () => context.push('/profile/activity'),
            ).animate().slideX(delay: 300.ms),
            
            _ProfileMenuItem(
              icon: Icons.favorite_border,
              title: 'Favoritos',
              onTap: () => context.push('/profile/favorites'),
            ).animate().slideX(delay: 350.ms),

            const SizedBox(height: 32),

            OutlinedButton.icon(
              onPressed: () {
                authProvider.logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sair', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: context.textStyles.titleMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
