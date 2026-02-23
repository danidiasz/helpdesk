import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/auth_provider.dart';
import '../../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountDataScreen extends StatefulWidget {
  const AccountDataScreen({super.key});

  @override
  State<AccountDataScreen> createState() => _AccountDataScreenState();
}

class _AccountDataScreenState extends State<AccountDataScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados da Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, size: 40, color: AppColors.primary),
             ).animate().scale(),
             const SizedBox(height: 24),
             TextField(
               controller: _nameController,
               decoration: const InputDecoration(labelText: 'Nome Completo'),
             ).animate().fadeIn().slideX(begin: -0.1, end: 0),
             const SizedBox(height: 16),
             TextField(
               controller: _emailController,
               decoration: const InputDecoration(labelText: 'Email'),
               enabled: false, // Usually email is immutable or requires verification
             ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () {
                   context.read<AuthProvider>().updateProfile(_nameController.text);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Perfil atualizado com sucesso!')),
                   );
                 },
                 child: const Text('Salvar Alterações'),
               ),
             ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}
