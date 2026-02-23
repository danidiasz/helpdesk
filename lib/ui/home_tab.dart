import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/auth_provider.dart';
import '../data/data_provider.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: const AssetImage('assets/images/avatar.png'), // Placeholder
                            onBackgroundImageError: (_, __) {},
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-Vindo(a)!',
                                style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
                              ),
                              Text(
                                user?.name ?? 'Usuário',
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.5, end: 0),
                      const Spacer(),
                      // Search Bar
                      GestureDetector(
                        onTap: () => context.push('/chat'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Faça sua pergunta aqui',
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.search, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Categories Section
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categorias', style: context.textStyles.titleLarge),
                      TextButton(
                        onPressed: () => context.push('/categories'),
                        child: Text(
                          'Mostrar tudo',
                          style: context.textStyles.labelMedium?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Show only first 6 categories
                      final categories = dataProvider.categories.take(6).toList();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _CategoryCard(category: category);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top Questions Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text('Top Perguntas', style: context.textStyles.titleLarge),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final faq = dataProvider.topFaqs[index];
                  return _FAQCard(faq: faq);
                },
                childCount: dataProvider.topFaqs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final dynamic category; // Avoid importing models directly if not necessary, but here we do via data_provider import

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    // Map string icon name to IconData
    IconData iconData;
    switch (category.iconName) {
      case 'domain': iconData = Icons.domain; break;
      case 'people': iconData = Icons.people; break;
      case 'access_time': iconData = Icons.access_time; break;
      case 'settings': iconData = Icons.settings; break;
      case 'verified': iconData = Icons.verified; break;
      case 'task': iconData = Icons.task; break;
      case 'attach_money': iconData = Icons.attach_money; break;
      case 'person_pin': iconData = Icons.person_pin; break;
      default: iconData = Icons.category;
    }

    return GestureDetector(
      onTap: () => context.push('/category/${category.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: Color(category.colorValue),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: context.textStyles.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 100.ms);
  }
}

class _FAQCard extends StatelessWidget {
  final dynamic faq;

  const _FAQCard({required this.faq});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/faq/${faq.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faq.subject,
              style: context.textStyles.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              faq.question,
              style: context.textStyles.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
