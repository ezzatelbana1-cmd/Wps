import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/document.dart';

/// مخزن المستندات: حفظ محلي دائم على الجهاز.
class DocumentStore extends ChangeNotifier {
  static const _key = 'docs_v1';

  final SharedPreferences _prefs;
  final List<Doc> _docs = [];

  DocumentStore(this._prefs) {
    _load();
  }

  /// المستندات مرتبة من الأحدث للأقدم.
  List<Doc> get docs {
    final list = List<Doc>.from(_docs);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int get count => _docs.length;

  /// الحجم التقريبي للمحتوى بالبايت.
  int get totalBytes =>
      _docs.fold<int>(0, (sum, d) => sum + utf8.encode(d.content).length);

  Doc? byId(String id) {
    for (final d in _docs) {
      if (d.id == id) return d;
    }
    return null;
  }

  Doc create(DocType type) {
    final doc = Doc(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: type.defaultTitle,
      type: type,
      content: '',
      updatedAt: DateTime.now(),
    );
    _docs.add(doc);
    _save();
    return doc;
  }

  void update(String id, {String? title, String? content}) {
    final i = _docs.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _docs[i] = _docs[i].copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
    );
    _save();
  }

  void toggleFavorite(String id) {
    final i = _docs.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _docs[i] = _docs[i].copyWith(favorite: !_docs[i].favorite);
    _save();
  }

  void duplicate(String id) {
    final src = byId(id);
    if (src == null) return;
    _docs.add(Doc(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '${src.title} (نسخة)',
      type: src.type,
      content: src.content,
      updatedAt: DateTime.now(),
    ));
    _save();
  }

  void delete(String id) {
    _docs.removeWhere((d) => d.id == id);
    _save();
  }

  void clear() {
    _docs.clear();
    _save();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _docs
        ..clear()
        ..addAll(list.map((e) => Doc.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      // بيانات تالفة: نبدأ من جديد بدل ما التطبيق يقع.
      _docs.clear();
    }
  }

  void _save() {
    _prefs.setString(_key, jsonEncode(_docs.map((d) => d.toJson()).toList()));
    notifyListeners();
  }
}
