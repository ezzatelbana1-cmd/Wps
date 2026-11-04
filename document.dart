import 'package:flutter/material.dart';

enum DocType { doc, sheet, slide }

extension DocTypeInfo on DocType {
  String get label => switch (this) {
        DocType.doc => 'مستند',
        DocType.sheet => 'جداول',
        DocType.slide => 'عرض',
      };

  String get extension => switch (this) {
        DocType.doc => 'docx',
        DocType.sheet => 'xlsx',
        DocType.slide => 'pptx',
      };

  String get defaultTitle => switch (this) {
        DocType.doc => 'مستند جديد',
        DocType.sheet => 'جدول بيانات جديد',
        DocType.slide => 'عرض تقديمي جديد',
      };

  IconData get icon => switch (this) {
        DocType.doc => Icons.description,
        DocType.sheet => Icons.table_chart,
        DocType.slide => Icons.slideshow,
      };

  Color get color => switch (this) {
        DocType.doc => Colors.blue,
        DocType.sheet => Colors.green,
        DocType.slide => Colors.orange,
      };
}

class Doc {
  final String id;
  final String title;
  final DocType type;
  final String content;
  final DateTime updatedAt;
  final bool favorite;

  const Doc({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.updatedAt,
    this.favorite = false,
  });

  String get fileName => '$title.${type.extension}';

  Doc copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? favorite,
  }) {
    return Doc(
      id: id,
      title: title ?? this.title,
      type: type,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
        'favorite': favorite,
      };

  factory Doc.fromJson(Map<String, dynamic> json) {
    return Doc(
      id: json['id'] as String,
      title: json['title'] as String,
      type: DocType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocType.doc,
      ),
      content: (json['content'] as String?) ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      favorite: (json['favorite'] as bool?) ?? false,
    );
  }
}
