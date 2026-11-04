import 'package:flutter/material.dart';

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
