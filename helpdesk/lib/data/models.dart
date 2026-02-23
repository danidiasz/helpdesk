import 'package:flutter/foundation.dart';

enum UserRole {
  admin,
  user,
}

class User {
  final String id;
  final String name;
  final String email;
  final String password; // In real app, never store plain text
  final UserRole role;
  final String roleName; // "teste" for user, "admin" for admin

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.roleName,
  });
}

class Category {
  final String id;
  final String name;
  final String iconName; // e.g. "school", "business" - we will map to Icons
  final int colorValue; // e.g. 0xFF...

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
  });
}

class FAQItem {
  final String id;
  final String categoryId;
  final String subject;
  final String question;
  final String answer;
  final List<String> keywords;
  final String authorId; // Who added it (admin)
  final DateTime createdAt;
  int viewCount;

  FAQItem({
    required this.id,
    required this.categoryId,
    required this.subject,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.authorId,
    required this.createdAt,
    this.viewCount = 0,
  });
}

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatSession {
  final String id;
  final String userId;
  final String subject;
  final String preview; // First few words of the first question
  final DateTime startedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.userId,
    required this.subject,
    required this.preview,
    required this.startedAt,
    required this.messages,
  });
}

class Suggestion {
  final String id;
  final String userId;
  final String question;
  final String answer; // Proposed answer
  final String subject;
  final bool isApproved;
  final DateTime createdAt;

  Suggestion({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    required this.subject,
    this.isApproved = false,
    required this.createdAt,
  });
}

class FileItem {
  final String id;
  final String name;
  final String subject; // Added subject
  final String categoryId;
  final String path; // Or url if uploaded
  final int size;
  final DateTime uploadDate;
  final String type; // 'pdf', 'txt', etc.
  /// OpenAI file id (e.g., file_...).
  final String? openAiFileId;
  /// OpenAI vector store file id (e.g., vsf_...), returned when added to a vector store.
  final String? openAiVectorStoreFileId;

  FileItem({
    required this.id,
    required this.name,
    this.subject = '', // Default empty
    required this.categoryId,
    required this.path,
    required this.size,
    required this.uploadDate,
    required this.type,
    this.openAiFileId,
    this.openAiVectorStoreFileId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'categoryId': categoryId,
    'path': path,
    'size': size,
    'uploadDate': uploadDate.toIso8601String(),
    'type': type,
    'openAiFileId': openAiFileId,
    'openAiVectorStoreFileId': openAiVectorStoreFileId,
  };

  static FileItem? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final name = json['name'] as String?;
      final categoryId = json['categoryId'] as String?;
      final path = json['path'] as String?;
      final size = json['size'];
      final uploadDate = json['uploadDate'] as String?;
      final type = json['type'] as String?;
      if (id == null || name == null || categoryId == null || path == null || size == null || uploadDate == null || type == null) return null;
      return FileItem(
        id: id,
        name: name,
        subject: (json['subject'] as String?) ?? '',
        categoryId: categoryId,
        path: path,
        size: (size is int) ? size : int.tryParse(size.toString()) ?? 0,
        uploadDate: DateTime.tryParse(uploadDate) ?? DateTime.now(),
        type: type,
        openAiFileId: json['openAiFileId'] as String?,
        openAiVectorStoreFileId: json['openAiVectorStoreFileId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
