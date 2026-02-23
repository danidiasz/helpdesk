import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/data_provider.dart';
import '../../data/models.dart';
import '../../data/auth_provider.dart';
import '../../theme.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final _subjectController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console - Adicionar FAQ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alimentar Base de Conhecimento', style: context.textStyles.titleLarge),
            const SizedBox(height: 24),
            
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: dataProvider.categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Assunto'),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Pergunta'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'Resposta (Base para IA)'),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFAQ,
                child: const Text('Adicionar à Base de Dados'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveFAQ() {
    if (_selectedCategoryId == null || 
        _subjectController.text.isEmpty || 
        _questionController.text.isEmpty || 
        _answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    
    final newFAQ = FAQItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: _selectedCategoryId!,
      subject: _subjectController.text,
      question: _questionController.text,
      answer: _answerController.text,
      keywords: _subjectController.text.split(' '),
      authorId: user?.id ?? 'admin',
      createdAt: DateTime.now(),
    );

    context.read<DataProvider>().addFAQ(newFAQ);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAQ adicionado com sucesso!')),
    );
    
    // Clear form
    _subjectController.clear();
    _questionController.clear();
    _answerController.clear();
    setState(() {
      _selectedCategoryId = null;
    });
  }
}
