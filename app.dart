import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/document_store.dart';
import 'services/settings_store.dart';

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
