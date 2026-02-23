import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/data_provider.dart';
import '../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<DataProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas as Categorias'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          // Simple card
          return GestureDetector(
            onTap: () => context.push('/category/${category.id}'),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Color(category.colorValue).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Color(category.colorValue).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(category.iconName),
                    size: 48,
                    color: Color(category.colorValue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category.name,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).animate().scale(delay: (index * 50).ms);
        },
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
