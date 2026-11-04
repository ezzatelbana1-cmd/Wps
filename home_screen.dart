import 'package:flutter/material.dart';

import '../models/document.dart';
import 'dashboard_tab.dart';
import 'editor_screen.dart';
import 'pdf_tools_screen.dart';
import 'profile_tab.dart';
import 'storage_tab.dart';

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
