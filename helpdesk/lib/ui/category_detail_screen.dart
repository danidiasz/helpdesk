import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/data_provider.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final category = dataProvider.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception('Categoria não encontrada'),
    );

    final faqs = dataProvider.faqs.where((f) => f.categoryId == categoryId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: Color(category.colorValue),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(category.colorValue),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Icon(
              _getIcon(category.iconName),
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
          ).animate().slideY(begin: -0.2, end: 0),

          // Search in category (optional, but good UX)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar em ${category.name}...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // Since this is a simple local filter, we could implement a local state variable
                // But for now, let's keep it simple.
              },
            ),
          ),

          // List
          Expanded(
            child: faqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma pergunta encontrada nesta categoria.',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => context.push('/faq/${faq.id}'),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  faq.subject,
                                  style: context.textStyles.titleMedium?.copyWith(
                                    color: Color(category.colorValue),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  faq.question,
                                  style: context.textStyles.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  faq.answer,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  IconData _getIcon(String name) {
     switch (name) {
      case 'domain': return Icons.domain;
      case 'people': return Icons.people;
      case 'access_time': return Icons.access_time;
      case 'settings': return Icons.settings;
      case 'verified': return Icons.verified;
      case 'task': return Icons.task;
      case 'attach_money': return Icons.attach_money;
      case 'person_pin': return Icons.person_pin;
      default: return Icons.category;
    }
  }
}
