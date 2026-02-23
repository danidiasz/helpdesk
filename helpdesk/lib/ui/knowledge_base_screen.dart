import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helpdesk/data/data_provider.dart';
import 'package:helpdesk/data/models.dart';
import 'package:helpdesk/theme.dart';
import 'package:helpdesk/openai/openai_services.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Conhecimento'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Perguntas e Respostas'),
            Tab(text: 'Arquivos (PDF)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ManageFAQsTab(),
          _ManageFilesTab(),
        ],
      ),
    );
  }
}

class _ManageFAQsTab extends StatelessWidget {
  const _ManageFAQsTab();

  void _showFAQDialog(BuildContext context, {FAQItem? faq}) {
    final isEditing = faq != null;
    final subjectController = TextEditingController(text: faq?.subject);
    final questionController = TextEditingController(text: faq?.question);
    final answerController = TextEditingController(text: faq?.answer);
    final keywordsController = TextEditingController(text: faq?.keywords.join(', '));
    String? selectedCategoryId = faq?.categoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final categories = context.read<DataProvider>().categories;
          return AlertDialog(
            title: Text(isEditing ? 'Editar FAQ' : 'Nova FAQ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedCategoryId = val),
                  ),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Assunto'),
                  ),
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(labelText: 'Pergunta'),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: answerController,
                    decoration: const InputDecoration(labelText: 'Resposta'),
                    maxLines: 4,
                  ),
                  TextField(
                    controller: keywordsController,
                    decoration: const InputDecoration(labelText: 'Palavras-chave (separadas por vírgula)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedCategoryId == null || subjectController.text.isEmpty) return;
                  
                  final newFaq = FAQItem(
                    id: isEditing ? faq!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    categoryId: selectedCategoryId!,
                    subject: subjectController.text,
                    question: questionController.text,
                    answer: answerController.text,
                    keywords: keywordsController.text.split(',').map((e) => e.trim()).toList(),
                    authorId: 'admin', // Mock
                    createdAt: isEditing ? faq!.createdAt : DateTime.now(),
                    viewCount: isEditing ? faq!.viewCount : 0,
                  );

                  if (isEditing) {
                    context.read<DataProvider>().updateFAQ(faq!.id, newFaq);
                  } else {
                    context.read<DataProvider>().addFAQ(newFaq);
                  }
                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'Salvar' : 'Adicionar'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqs = context.watch<DataProvider>().faqs;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFAQDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            child: ListTile(
              title: Text(faq.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(faq.question, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showFAQDialog(context, faq: faq),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Confirm dialog
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir FAQ?'),
                          content: const Text('Esta ação não pode ser desfeita.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () {
                                context.read<DataProvider>().deleteFAQ(faq.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManageFilesTab extends StatefulWidget {
  const _ManageFilesTab();

  @override
  State<_ManageFilesTab> createState() => _ManageFilesTabState();
}

class _ManageFilesTabState extends State<_ManageFilesTab> {
  bool _isUploading = false;
  bool _isRefreshing = false;

  Future<String> _ensureVectorStoreId(BuildContext context) async {
    final provider = context.read<DataProvider>();
    final currentId = provider.openAiVectorStoreId;
    final id = await OpenAIService.ensureVectorStore(existingId: currentId, name: 'HelpDesk AI Knowledge Base');
    if (currentId != id) await provider.setOpenAiVectorStoreId(id);
    return id;
  }

  Future<void> _refreshFromOpenAI() async {
    final provider = context.read<DataProvider>();
    final vectorStoreId = provider.openAiVectorStoreId;
    if (vectorStoreId == null || vectorStoreId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum Vector Store configurado ainda. Envie um PDF primeiro.')));
      }
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      final remote = await OpenAIService.listVectorStoreFiles(vectorStoreId: vectorStoreId);
      final remoteIds = remote.map((e) => e['id']).whereType<String>().toSet();
      final kept = provider.files.where((f) {
        final vsf = f.openAiVectorStoreFileId;
        return vsf == null || remoteIds.contains(vsf);
      }).toList();

      // Replace local list only by removing items that are no longer in OpenAI.
      for (final f in provider.files.toList()) {
        if (!kept.any((k) => k.id == f.id)) provider.deleteFile(f.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronizado com a OpenAI.')));
      }
    } catch (e) {
      debugPrint('Refresh from OpenAI failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sincronizar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: true, // Necessary for web to get bytes
      );

      if (result != null) {
        setState(() => _isUploading = true);

        final vectorStoreId = await _ensureVectorStoreId(context);

        final name = result.files.first.name;
        final bytes = result.files.first.bytes;
        if (bytes == null) throw Exception('Falha ao ler bytes do arquivo.');
        // Default subject is name without extension
        final subject = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;

        final uploaded = await OpenAIService.uploadPdfBytes(bytes: bytes, filename: name);
        final vsfId = await OpenAIService.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploaded.fileId);

        final file = FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          subject: subject,
          categoryId: 'general', // Default
          path: 'openai://files/${uploaded.fileId}',
          size: uploaded.bytes,
          uploadDate: DateTime.now(),
          type: result.files.first.extension ?? 'pdf',
          openAiFileId: uploaded.fileId,
          openAiVectorStoreFileId: vsfId,
        );

        if (mounted) {
          context.read<DataProvider>().addFile(file);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo enviado e indexado com sucesso na OpenAI!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Upload file failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar arquivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _editFileDetails(FileItem file) {
    String? selectedCategoryId = file.categoryId == 'general' ? null : file.categoryId; 
    final subjectController = TextEditingController(text: file.subject);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
           final categories = context.read<DataProvider>().categories;
           return AlertDialog(
            title: const Text('Editar Detalhes do Arquivo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: categories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories.map((c) {
                     return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategoryId = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Assunto'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                   if (selectedCategoryId != null) {
                     final newFile = FileItem(
                       id: file.id,
                       name: file.name,
                       subject: subjectController.text,
                       categoryId: selectedCategoryId!,
                       path: file.path,
                       size: file.size,
                       uploadDate: file.uploadDate,
                       type: file.type,
                     );
                     context.read<DataProvider>().updateFile(file.id, newFile);
                   }
                   Navigator.pop(context);
                }, 
                child: const Text('Salvar')
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = context.watch<DataProvider>().files;

    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Enviando para o OpenAI...'),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadFile,
        icon: const Icon(Icons.upload_file),
        label: const Text('Enviar PDF'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Arquivos indexados na OpenAI',
                    style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Sincronizar',
                  onPressed: _isRefreshing ? null : _refreshFromOpenAI,
                  icon: _isRefreshing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                ),
              ],
            ),
          ),
          Expanded(
            child: files.isEmpty
                ? const Center(child: Text('Nenhum arquivo enviado.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final categoryName = context.read<DataProvider>().categories
                          .firstWhere((c) => c.id == file.categoryId, orElse: () => Category(id: '', name: 'Geral', iconName: '', colorValue: 0))
                          .name;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(file.subject.isNotEmpty ? file.subject : file.name),
                          subtitle: Text('Arquivo: ${file.name}\nCategoria: $categoryName • ${(file.size / 1024).toStringAsFixed(1)} KB'),
                          isThreeLine: true,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Editar Detalhes')),
                              const PopupMenuItem(value: 'delete', child: Text('Excluir da OpenAI', style: TextStyle(color: Colors.red))),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _editFileDetails(file);
                                return;
                              }
                              if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir arquivo?'),
                                    content: const Text('Remove o arquivo da OpenAI (e do índice). Essa ação não pode ser desfeita.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                try {
                                  final vectorStoreId = await _ensureVectorStoreId(context);
                                  final vsf = file.openAiVectorStoreFileId;
                                  if (vsf != null && vsf.isNotEmpty) {
                                    await OpenAIService.deleteVectorStoreFile(vectorStoreId: vectorStoreId, vectorStoreFileId: vsf);
                                  }
                                  final fid = file.openAiFileId;
                                  if (fid != null && fid.isNotEmpty) {
                                    await OpenAIService.deleteFile(fileId: fid);
                                  }
                                  if (mounted) context.read<DataProvider>().deleteFile(file.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo excluído da OpenAI.')));
                                  }
                                } catch (e) {
                                  debugPrint('Delete file failed: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
