import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/data_provider.dart';
import '../../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActivityCenterScreen extends StatelessWidget {
  const ActivityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Central de Atividade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _StatCard(
              title: 'Perguntas Realizadas',
              value: '${dataProvider.questionsAskedCount}',
              icon: Icons.chat_bubble_outline,
              color: AppColors.primary,
              onTap: () => context.go('/history'), // Switch to history tab
            ).animate().slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 16),
            
            _StatCard(
              title: 'Perguntas Visualizadas',
              value: '${dataProvider.faqsViewedCount}',
              icon: Icons.visibility_outlined,
              color: AppColors.secondary,
            ).animate().slideX(begin: 0.1, end: 0),
            
            const SizedBox(height: 16),
            
            _StatCard(
              title: 'Sugestões Enviadas',
              value: '${dataProvider.suggestionsMadeCount}',
              icon: Icons.lightbulb_outline,
              color: AppColors.tertiary,
              onTap: () => context.go('/suggestions'), // Switch to suggestions tab
            ).animate().slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: context.textStyles.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (onTap != null)
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
