import 'package:flutter/material.dart';

import '../app.dart';
import '../models/document.dart';
import '../utils/format.dart';
import 'editor_screen.dart';
import 'pdf_tools_screen.dart';

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
