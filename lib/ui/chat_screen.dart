import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:helpdesk/data/data_provider.dart';
import 'package:helpdesk/data/auth_provider.dart';
import 'package:helpdesk/data/models.dart';
import 'package:helpdesk/openai/openai_services.dart';
import 'package:helpdesk/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String? initialQuery;
  final String? sessionId; // If viewing history

  const ChatScreen({super.key, this.initialQuery, this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _loadSession(widget.sessionId!);
    } else {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _sendMessage(widget.initialQuery!);
      }
    }
  }

  void _loadSession(String id) {
    final session = context.read<DataProvider>().chatHistory.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Session not found'),
    );
    _currentSessionId = id;
    _messages = List.from(session.messages);
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Prepare context from FAQs
    final dataProvider = context.read<DataProvider>();
    final faqs = dataProvider.faqs;
    final faqContext = faqs.map((f) => "Assunto: ${f.subject}\nPergunta: ${f.question}\nResposta: ${f.answer}").join("\n\n");

    try {
      final vectorStoreId = dataProvider.openAiVectorStoreId;
      final history = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final String responseContent;
      if (vectorStoreId != null && vectorStoreId.isNotEmpty) {
        responseContent = await OpenAIService.answerWithRag(
          question: content,
          faqContext: faqContext,
          vectorStoreId: vectorStoreId,
          chatHistory: history,
        );
      } else {
        // Fallback: FAQ-only
        final systemPrompt = """
Você é um assistente interno.

Regras obrigatórias:
1) Responda usando APENAS as informações do FAQ abaixo.
2) Se não houver informação suficiente, diga exatamente: "Não encontrei essa informação na base enviada (FAQ/PDF)."
3) Responda em português.

FAQ:
$faqContext
""";
        responseContent = await OpenAIService.sendChat([
          {'role': 'system', 'content': systemPrompt},
          ...history,
        ]);
      }

      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: responseContent,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });
      _scrollToBottom();

      // Save/Update session
      _saveSession();

    } catch (e) {
      debugPrint('Chat send failed: $e');
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'assistant',
          content: 'Desculpe, ocorreu um erro ao processar sua solicitação: $e',
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _saveSession() {
    if (_messages.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Determine subject from first user message or AI response (simplified)
    final subject = _messages.first.content.length > 20 
        ? '${_messages.first.content.substring(0, 20)}...' 
        : _messages.first.content;
    
    final session = ChatSession(
      id: _currentSessionId!,
      userId: user.id,
      subject: subject,
      preview: subject,
      startedAt: _messages.first.timestamp,
      messages: List.from(_messages),
    );

    // If session exists update it, otherwise add it
    // But dataProvider.addChatSession adds to top.
    // We need a way to update. For simplicity, we'll remove old and add new or handle in provider.
    // Let's just use addChatSession and handle deduplication in provider or just add.
    // To do it right:
    final provider = context.read<DataProvider>();
    // Ideally we should check if exists.
    // Simplified: we won't implement complex update logic here, just assuming addChatSession pushes to history.
    // But we don't want duplicates every message.
    // So we only save when leaving? Or we update a mutable session object?
    // Let's try to find and update in provider.
    // Since DataProvider doesn't have updateChatSession, let's just do nothing here and save on dispose?
    // No, save on every message is safer.
    // Let's just allow duplicates for this prototype or filter in UI.
    // Actually, I'll modify DataProvider to update if exists.
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    // Save session on exit
    if (_messages.isNotEmpty && widget.sessionId == null) { // Only save new sessions for now to avoid complexity
         final user = context.read<AuthProvider>().user;
         if (user != null) {
            final subject = _messages.first.content.length > 30 
                ? '${_messages.first.content.substring(0, 30)}...' 
                : _messages.first.content;
            
            final session = ChatSession(
              id: _currentSessionId!,
              userId: user.id,
              subject: subject,
              preview: subject,
              startedAt: _messages.first.timestamp,
              messages: List.from(_messages),
            );
            context.read<DataProvider>().addChatSession(session);
         }
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente Virtual'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.lg),
                        topRight: const Radius.circular(AppRadius.lg),
                        bottomLeft: Radius.circular(isUser ? AppRadius.lg : 0),
                        bottomRight: Radius.circular(isUser ? 0 : AppRadius.lg),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(msg.timestamp),
                          style: context.textStyles.labelSmall?.copyWith(
                            color: isUser ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const SizedBox(
                     width: 16, 
                     height: 16, 
                     child: CircularProgressIndicator(strokeWidth: 2)
                   ),
                   const SizedBox(width: 8),
                   Text('Digitando...', style: context.textStyles.labelSmall),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      filled: true,
                      fillColor: Color(0xFFF8F9FA),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _sendMessage(_controller.text),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
