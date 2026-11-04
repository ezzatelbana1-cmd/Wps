import 'package:flutter/material.dart';

import '../app.dart';
import '../utils/format.dart';

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
