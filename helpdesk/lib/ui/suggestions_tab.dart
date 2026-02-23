import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/data_provider.dart';
import '../data/auth_provider.dart';
import '../data/models.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SuggestionsTab extends StatelessWidget {
  const SuggestionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    final suggestions = dataProvider.suggestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugestões'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Admin settings for suggestions (optional)
              },
            ),
        ],
      ),
      body: suggestions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma sugestão ainda.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSuggestionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Sugestão'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                suggestion.subject,
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () {
                                  context.read<DataProvider>().removeSuggestion(suggestion.id);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          suggestion.question,
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.answer,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Sugerido por usuário', // We'd need user name lookup but simplified
                              style: context.textStyles.labelSmall,
                            ),
                            const Spacer(),
                            if (isAdmin)
                              IconButton(
                                icon: Icon(
                                  suggestion.isApproved ? Icons.star : Icons.star_border,
                                  color: suggestion.isApproved ? Colors.amber : AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  // Toggle approval logic (not implemented in provider yet but visually here)
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: suggestions.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddSuggestionDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddSuggestionDialog(BuildContext context) {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Sugestão'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Assunto'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: 'Pergunta'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Resposta Sugerida'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.isNotEmpty && subjectController.text.isNotEmpty) {
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  context.read<DataProvider>().addSuggestion(
                    Suggestion(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: user.id,
                      question: questionController.text,
                      answer: answerController.text,
                      subject: subjectController.text,
                      createdAt: DateTime.now(),
                    ),
                  );
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
