import 'package:flutter/material.dart';

import '../app.dart';
import '../models/document.dart';
import '../utils/format.dart';

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
