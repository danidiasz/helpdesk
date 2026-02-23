import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/data_provider.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FAQDetailScreen extends StatefulWidget {
  final String faqId;

  const FAQDetailScreen({super.key, required this.faqId});

  @override
  State<FAQDetailScreen> createState() => _FAQDetailScreenState();
}

class _FAQDetailScreenState extends State<FAQDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Increment view count on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().incrementFAQView(widget.faqId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    
    // Find FAQ
    dynamic faq;
    try {
      faq = dataProvider.faqs.firstWhere((f) => f.id == widget.faqId);
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Pergunta não encontrada')),
      );
    }

    final isFavorite = dataProvider.isFavorite(widget.faqId);
    
    // Find Category for color
    final category = dataProvider.categories.firstWhere(
      (c) => c.id == faq.categoryId,
      orElse: () => dataProvider.categories.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(faq.subject),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : AppColors.textPrimary,
            ),
            onPressed: () {
              dataProvider.toggleFavorite(widget.faqId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Color(category.colorValue).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(category.colorValue),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          category.name,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${faq.viewCount} visualizações',
                        style: context.textStyles.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    faq.question,
                    style: context.textStyles.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Answer Section
            Text(
              'Resposta',
              style: context.textStyles.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                faq.answer,
                style: context.textStyles.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
            
            // Helpful?
            Center(
              child: Column(
                children: [
                  Text(
                    'Essa resposta foi útil?',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.thumb_up_outlined),
                        label: const Text('Sim'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.thumb_down_outlined),
                        label: const Text('Não'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
