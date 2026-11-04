import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/document.dart';
import '../services/document_store.dart';
import '../utils/format.dart';

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
