import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/data_provider.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SearchHistoryTab extends StatelessWidget {
  const SearchHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<DataProvider>().chatHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Buscas')),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum histórico encontrado.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final session = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withOpacity(0.1),
                      child: const Icon(Icons.chat_bubble_outline, color: AppColors.secondary),
                    ),
                    title: Text(
                      session.subject,
                      style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          session.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(session.startedAt),
                          style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/chat?sessionId=${session.id}'),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1, end: 0);
              },
            ),
    );
  }
}
