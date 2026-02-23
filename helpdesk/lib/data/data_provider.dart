import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart'; // We don't have uuid package, let's just use random strings
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class DataProvider extends ChangeNotifier {
  static const _prefsKeyVectorStoreId = 'openai_vector_store_id';
  static const _prefsKeyFiles = 'kb_files_v1';

  bool _initialized = false;
  String? _openAiVectorStoreId;
  final List<Category> _categories = [
    Category(id: '1', name: 'Dominio', iconName: 'domain', colorValue: 0xFF5E60CE),
    Category(id: '2', name: 'Dúvidas Clientes', iconName: 'people', colorValue: 0xFF4EA8DE),
    Category(id: '3', name: 'Acessórias', iconName: 'access_time', colorValue: 0xFF56CFE1),
    Category(id: '4', name: 'OSAYK', iconName: 'settings', colorValue: 0xFF72EFDD),
    Category(id: '5', name: 'Veri', iconName: 'verified', colorValue: 0xFF80FFDB),
    Category(id: '6', name: 'Obrigações', iconName: 'task', colorValue: 0xFF64DFDF),
    Category(id: '7', name: 'Financeiro', iconName: 'attach_money', colorValue: 0xFF5390D9),
    Category(id: '8', name: 'RH', iconName: 'person_pin', colorValue: 0xFF48BFE3),
  ];

  final List<FAQItem> _faqs = [
    FAQItem(
      id: '1',
      categoryId: '1',
      subject: 'Configuração de Domínio',
      question: 'Como configuro meu domínio no painel?',
      answer: 'Para configurar seu domínio, acesse Configurações > Domínios e clique em Adicionar Novo.',
      keywords: ['domínio', 'configuração', 'painel'],
      authorId: '1',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      viewCount: 15,
    ),
    FAQItem(
      id: '2',
      categoryId: '2',
      subject: 'Reembolso',
      question: 'Qual a política de reembolso para clientes?',
      answer: 'O reembolso pode ser solicitado até 7 dias após a compra, conforme o CDC.',
      keywords: ['reembolso', 'cliente', 'política'],
      authorId: '1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      viewCount: 42,
    ),
    FAQItem(
      id: '3',
      categoryId: '6',
      subject: 'Prazo de Entrega',
      question: 'Qual o prazo padrão para entrega de obrigações?',
      answer: 'O prazo padrão é de 5 dias úteis após o recebimento da documentação completa.',
      keywords: ['prazo', 'entrega', 'obrigações'],
      authorId: '1',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      viewCount: 8,
    ),
  ];

  final List<ChatSession> _chatHistory = [];
  final List<Suggestion> _suggestions = [];
  final List<FileItem> _files = [];
  final Set<String> _favorites = {}; // Set of FAQ IDs

  // Activity Stats
  int _questionsAskedCount = 0;
  int _faqsViewedCount = 0;
  int _suggestionsMadeCount = 0;

  List<Category> get categories => _categories;
  List<FAQItem> get faqs => _faqs;
  List<ChatSession> get chatHistory => _chatHistory;
  List<Suggestion> get suggestions => _suggestions;
  List<FileItem> get files => _files;
  bool get initialized => _initialized;
  String? get openAiVectorStoreId => _openAiVectorStoreId;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _openAiVectorStoreId = prefs.getString(_prefsKeyVectorStoreId);
      final rawFiles = prefs.getString(_prefsKeyFiles);
      if (rawFiles != null && rawFiles.isNotEmpty) {
        final decoded = jsonDecode(rawFiles);
        if (decoded is List) {
          _files
            ..clear()
            ..addAll(decoded
                .whereType<Map>()
                .map((e) => FileItem.fromJson(e.cast<String, dynamic>()))
                .whereType<FileItem>());
        }
      }
    } catch (e) {
      debugPrint('DataProvider.init failed: $e');
      // Default to empty persistence.
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setOpenAiVectorStoreId(String? id) async {
    _openAiVectorStoreId = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null || id.isEmpty) {
        await prefs.remove(_prefsKeyVectorStoreId);
      } else {
        await prefs.setString(_prefsKeyVectorStoreId, id);
      }
    } catch (e) {
      debugPrint('Failed to persist vector store id: $e');
    }
  }

  Future<void> _persistFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_files.map((f) => f.toJson()).toList());
      await prefs.setString(_prefsKeyFiles, encoded);
    } catch (e) {
      debugPrint('Failed to persist files: $e');
    }
  }
  
  // Getters for specific data
  List<FAQItem> get topFaqs => _faqs.take(5).toList(); // Mock 'top' logic
  List<FAQItem> getFavoriteFaqs() => _faqs.where((f) => _favorites.contains(f.id)).toList();

  // Stats getters
  int get questionsAskedCount => _questionsAskedCount;
  int get faqsViewedCount => _faqsViewedCount;
  int get suggestionsMadeCount => _suggestionsMadeCount;

  // Actions
  void addCategory(Category category) {
    _categories.add(category);
    notifyListeners();
  }

  void addFAQ(FAQItem faq) {
    _faqs.add(faq);
    notifyListeners();
  }

  void updateFAQ(String id, FAQItem newFaq) {
    final index = _faqs.indexWhere((f) => f.id == id);
    if (index != -1) {
      _faqs[index] = newFaq;
      notifyListeners();
    }
  }

  void deleteFAQ(String id) {
    _faqs.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  void addFile(FileItem file) {
    _files.add(file);
    _persistFiles();
    notifyListeners();
  }

  void deleteFile(String id) {
    _files.removeWhere((f) => f.id == id);
    _persistFiles();
    notifyListeners();
  }

  void updateFile(String id, FileItem newFile) {
    final index = _files.indexWhere((f) => f.id == id);
    if (index != -1) {
      _files[index] = newFile;
      _persistFiles();
      notifyListeners();
    }
  }

  void incrementFAQView(String faqId) {
    final index = _faqs.indexWhere((f) => f.id == faqId);
    if (index != -1) {
      _faqs[index].viewCount++;
      _faqsViewedCount++;
      notifyListeners();
    }
  }

  void toggleFavorite(String faqId) {
    if (_favorites.contains(faqId)) {
      _favorites.remove(faqId);
    } else {
      _favorites.add(faqId);
    }
    notifyListeners();
  }

  bool isFavorite(String faqId) => _favorites.contains(faqId);

  void addChatSession(ChatSession session) {
    _chatHistory.insert(0, session);
    _questionsAskedCount++;
    notifyListeners();
  }

  void addSuggestion(Suggestion suggestion) {
    _suggestions.add(suggestion);
    _suggestionsMadeCount++;
    notifyListeners();
  }

  void removeSuggestion(String id) {
    _suggestions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Filter FAQs
  List<FAQItem> filterFaqs({String? categoryId, String? query}) {
    return _faqs.where((faq) {
      bool matchesCategory = categoryId == null || faq.categoryId == categoryId;
      bool matchesQuery = query == null || 
                          query.isEmpty || 
                          faq.question.toLowerCase().contains(query.toLowerCase()) ||
                          faq.subject.toLowerCase().contains(query.toLowerCase()) ||
                          faq.keywords.any((k) => k.toLowerCase().contains(query.toLowerCase()));
      return matchesCategory && matchesQuery;
    }).toList();
  }
}
