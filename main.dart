import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';


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


class SettingsStore extends ChangeNotifier {
  static const _darkKey = 'dark_mode';

  final SharedPreferences _prefs;
  bool _darkMode;

  SettingsStore(this._prefs) : _darkMode = _prefs.getBool(_darkKey) ?? false;

  bool get darkMode => _darkMode;

  set darkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    _prefs.setBool(_darkKey, value);
    notifyListeners();
  }
}


String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  return 'منذ ${diff.inDays} يوم';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes بايت';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
}

int wordCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// نافذة إدخال نص بسيطة (تستخدم لإعادة التسمية).
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );
  return result ?? false;
}



/// يمرر المخازن (Stores) لكل الشاشات بدون مكتبات إضافية.
class AppScope extends InheritedWidget {
  final DocumentStore docs;
  final SettingsStore settings;

  const AppScope({
    super.key,
    required this.docs,
    required this.settings,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope غير موجود في الشجرة');
    return scope!;
  }

  /// قراءة بدون اشتراك (مسموحة داخل initState).
  static AppScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope غير موجود في الشجرة');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class WpsCloneApp extends StatelessWidget {
  final DocumentStore docs;
  final SettingsStore settings;

  const WpsCloneApp({super.key, required this.docs, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      docs: docs,
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'WPS Office Clone',
            debugShowCheckedModeBanner: false,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.redAccent,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.redAccent,
              brightness: Brightness.dark,
            ),
            // واجهة عربية من اليمين لليسار
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}



class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _query = '';
  bool _onlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).docs;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = _query.trim().toLowerCase();
        final docs = store.docs.where((d) {
          if (_onlyFavorites && !d.favorite) return false;
          if (q.isEmpty) return true;
          return d.title.toLowerCase().contains(q) ||
              d.content.toLowerCase().contains(q);
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text('أنشئ جديداً',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final type in DocType.values)
                  _Shortcut(
                    icon: type.icon,
                    label: type.label,
                    color: type.color,
                    onTap: () => createAndOpen(context, type),
                  ),
                _Shortcut(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PdfToolsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث في الملفات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('الملفات',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilterChip(
                  label: const Text('المفضلة'),
                  avatar: const Icon(Icons.star, size: 18),
                  selected: _onlyFavorites,
                  onSelected: (v) => setState(() => _onlyFavorites = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (docs.isEmpty)
              _EmptyState(
                  hasDocs: store.count > 0,
                  onCreate: () => createAndOpen(context, DocType.doc))
            else
              for (final doc in docs) _DocTile(doc: doc),
          ],
        );
      },
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasDocs;
  final VoidCallback onCreate;

  const _EmptyState({required this.hasDocs, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(hasDocs ? 'لا توجد نتائج مطابقة' : 'لا توجد ملفات بعد'),
          if (!hasDocs) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('أنشئ أول مستند'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final Doc doc;

  const _DocTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).docs;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(doc.type.icon, color: doc.type.color, size: 36),
        title: Text(doc.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${timeAgo(doc.updatedAt)} • ${wordCount(doc.content)} كلمة'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doc.favorite)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            PopupMenuButton<String>(
              onSelected: (action) async {
                switch (action) {
                  case 'fav':
                    store.toggleFavorite(doc.id);
                  case 'rename':
                    final name = await askText(context,
                        title: 'إعادة تسمية', initial: doc.title);
                    if (name != null && name.isNotEmpty) {
                      store.update(doc.id, title: name);
                    }
                  case 'copy':
                    store.duplicate(doc.id);
                  case 'delete':
                    final ok = await confirm(context,
                        title: 'حذف الملف',
                        message: 'هل تريد حذف "${doc.fileName}" نهائياً؟');
                    if (ok) store.delete(doc.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'fav',
                  child: Text(doc.favorite
                      ? 'إزالة من المفضلة'
                      : 'إضافة للمفضلة'),
                ),
                const PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                const PopupMenuItem(value: 'copy', child: Text('نسخ')),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ],
        ),
        onTap: () => openDoc(context, doc.id),
      ),
    );
  }
}




/// ينشئ مستنداً جديداً ويفتحه في المحرر.
void createAndOpen(BuildContext context, DocType type) {
  final doc = AppScope.read(context).docs.create(type);
  openDoc(context, doc.id);
}

void openDoc(BuildContext context, String docId) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EditorScreen(docId: docId)),
  );
}

class EditorScreen extends StatefulWidget {
  final String docId;

  const EditorScreen({super.key, required this.docId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final DocumentStore _store;
  late final TextEditingController _controller;
  final UndoHistoryController _undo = UndoHistoryController();

  late Doc _doc;
  Timer? _debounce;
  bool _dirty = false;
  double _fontSize = 16;
  TextAlign _align = TextAlign.start;

  @override
  void initState() {
    super.initState();
    _store = AppScope.read(context).docs;
    // لو الملف اتحذف لأي سبب، نعرض مستند فاضي بدل ما نكسر الشاشة.
    _doc = _store.byId(widget.docId) ??
        Doc(
          id: widget.docId,
          title: 'مستند',
          type: DocType.doc,
          content: '',
          updatedAt: DateTime.now(),
        );
    _controller = TextEditingController(text: _doc.content);
  }

  void _onChanged(String _) {
    _dirty = true;
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() {
    if (!_dirty) return;
    _dirty = false;
    _store.update(widget.docId, content: _controller.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) {
      final id = widget.docId;
      final text = _controller.text;
      // نؤجل الحفظ لما تخلص مرحلة إزالة الشاشة.
      Future.microtask(() => _store.update(id, content: text));
    }
    _controller.dispose();
    _undo.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final name =
        await askText(context, title: 'إعادة تسمية', initial: _doc.title);
    if (name == null || name.isEmpty) return;
    _store.update(widget.docId, title: name);
    setState(() => _doc = _doc.copyWith(title: name));
  }

  void _manualSave() {
    _dirty = true;
    _save();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التغييرات')),
    );
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ النص')),
    );
  }

  String get _hint => switch (_doc.type) {
        DocType.doc => 'اكتب هنا...',
        DocType.sheet => 'اكتب بياناتك هنا (سطر لكل صف)...',
        DocType.slide => 'اكتب محتوى الشرائح هنا...',
      };

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _rename,
          child: Text('${_doc.title}.${_doc.type.extension}',
              style: const TextStyle(fontSize: 16)),
        ),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            icon: const Icon(Icons.save_outlined),
            onPressed: _manualSave,
          ),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            undo: _undo,
            align: _align,
            onAlign: (a) => setState(() => _align = a),
            onSmaller: () =>
                setState(() => _fontSize = (_fontSize - 2).clamp(10, 40)),
            onBigger: () =>
                setState(() => _fontSize = (_fontSize + 2).clamp(10, 40)),
            onCopy: _copyAll,
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                undoController: _undo,
                onChanged: _onChanged,
                maxLines: null,
                expands: true,
                textAlign: _align,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _hint,
                ),
                style: TextStyle(fontSize: _fontSize, height: 1.5),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${wordCount(text)} كلمة • ${text.length} حرف',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(_dirty ? 'جاري الحفظ...' : 'تم الحفظ',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final UndoHistoryController undo;
  final TextAlign align;
  final ValueChanged<TextAlign> onAlign;
  final VoidCallback onSmaller;
  final VoidCallback onBigger;
  final VoidCallback onCopy;

  const _Toolbar({
    required this.undo,
    required this.align,
    required this.onAlign,
    required this.onSmaller,
    required this.onBigger,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final selected = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ValueListenableBuilder<UndoHistoryValue>(
        valueListenable: undo,
        builder: (context, value, _) {
          return Row(
            children: [
              IconButton(
                tooltip: 'تراجع',
                icon: const Icon(Icons.undo),
                onPressed: value.canUndo ? undo.undo : null,
              ),
              IconButton(
                tooltip: 'إعادة',
                icon: const Icon(Icons.redo),
                onPressed: value.canRedo ? undo.redo : null,
              ),
              const SizedBox(height: 24, child: VerticalDivider()),
              IconButton(
                tooltip: 'تصغير الخط',
                icon: const Icon(Icons.text_decrease),
                onPressed: onSmaller,
              ),
              IconButton(
                tooltip: 'تكبير الخط',
                icon: const Icon(Icons.text_increase),
                onPressed: onBigger,
              ),
              const SizedBox(height: 24, child: VerticalDivider()),
              IconButton(
                tooltip: 'يمين',
                icon: Icon(Icons.format_align_right,
                    color: align == TextAlign.right ? selected : null),
                onPressed: () => onAlign(TextAlign.right),
              ),
              IconButton(
                tooltip: 'وسط',
                icon: Icon(Icons.format_align_center,
                    color: align == TextAlign.center ? selected : null),
                onPressed: () => onAlign(TextAlign.center),
              ),
              IconButton(
                tooltip: 'يسار',
                icon: Icon(Icons.format_align_left,
                    color: align == TextAlign.left ? selected : null),
                onPressed: () => onAlign(TextAlign.left),
              ),
              const SizedBox(height: 24, child: VerticalDivider()),
              IconButton(
                tooltip: 'نسخ كل النص',
                icon: const Icon(Icons.copy_all),
                onPressed: onCopy,
              ),
            ],
          );
        },
      ),
    );
  }
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['الرئيسية', 'الأدوات', 'التخزين', 'الإعدادات'];

  static const _tabs = <Widget>[
    DashboardTab(),
    PdfToolsBody(),
    StorageTab(),
    ProfileTab(),
  ];

  void _showCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in DocType.values)
              ListTile(
                leading: Icon(type.icon, color: type.color),
                title: Text('${type.label} جديد'),
                onTap: () {
                  Navigator.pop(ctx);
                  createAndOpen(context, type);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.folder_open), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.apps), label: 'الأدوات'),
          NavigationDestination(icon: Icon(Icons.storage), label: 'التخزين'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}


class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أدوات الـ PDF')),
      body: const PdfToolsBody(),
    );
  }
}

class PdfToolsBody extends StatelessWidget {
  const PdfToolsBody({super.key});

  static const _tools = [
    _Tool(Icons.picture_as_pdf_outlined, 'صورة إلى PDF', 'تحويل الصور بسهولة',
        Colors.redAccent),
    _Tool(Icons.merge_type, 'دمج ملفات PDF', 'تجميع عدة ملفات',
        Colors.blueAccent),
    _Tool(Icons.edit_document, 'توقيع PDF', 'إضافة توقيع إلكتروني',
        Colors.orangeAccent),
    _Tool(Icons.compress, 'ضغط ملف PDF', 'تقليل حجم الملف', Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('الأدوات الشائعة',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final tool in _tools) _ToolCard(tool: tool),
          ],
        ),
      ],
    );
  }
}

class _Tool {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Tool(this.icon, this.title, this.subtitle, this.color);
}

class _ToolCard extends StatelessWidget {
  final _Tool tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${tool.title}" قريباً في تحديث قادم')),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, color: tool.color, size: 28),
            const SizedBox(height: 8),
            Text(tool.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(tool.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.outline, fontSize: 11)),
            const SizedBox(height: 4),
            Text('قريباً',
                style: TextStyle(color: scheme.primary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}



class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return ListenableBuilder(
      listenable: scope.settings,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('الوضع الداكن'),
                    value: scope.settings.darkMode,
                    onChanged: (v) => scope.settings.darkMode = v,
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.language),
                    title: Text('لغة التطبيق'),
                    trailing: Text('العربية'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('حذف كل الملفات'),
                    onTap: () async {
                      final ok = await confirm(
                        context,
                        title: 'حذف كل الملفات',
                        message: 'سيتم حذف كل الملفات نهائياً من الجهاز. متأكد؟',
                      );
                      if (ok) scope.docs.clear();
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('حول الإصدار'),
                    trailing: Text('v1.0.0'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}



/// بدل تبويب "السحابة" الوهمي: إحصائيات التخزين المحلي الحقيقية.
class StorageTab extends StatelessWidget {
  const StorageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).docs;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final docs = store.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text('التخزين على الجهاز',
                          style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('${store.count} ملف • ${formatBytes(store.totalBytes)}',
                      style: TextStyle(color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final type in DocType.values)
              ListTile(
                leading: Icon(type.icon, color: type.color),
                title: Text(type.label),
                trailing: Text('${docs.where((d) => d.type == type).length}'),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('المزامنة السحابية'),
              subtitle: const Text('غير متاحة حالياً — الملفات محفوظة على جهازك فقط'),
            ),
          ],
        );
      },
    );
  }
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    WpsCloneApp(
      docs: DocumentStore(prefs),
      settings: SettingsStore(prefs),
    ),
  );
}

