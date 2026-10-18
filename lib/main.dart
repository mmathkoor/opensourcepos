import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/receive_page.dart';
import 'screens/report_page.dart';
import 'screens/sell_page.dart';
import 'screens/settings_page.dart';
import 'screens/stock_page.dart';
import 'store.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (details) => Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText('خطأ في الشاشة:\n${details.exception}'),
          ),
        );
    final storage = await _openStorage();
    runApp(DukkanApp(
      store: AppStore(raw: storage.raw, saver: storage.saver),
      note: storage.note,
    ));
  }, (error, stack) {
    runApp(_ErrorApp('$error\n\n$stack'));
  });
}

const _prefsKey = 'dukkan_data_v1';

class _Storage {
  _Storage({this.raw, this.saver, this.note});

  final String? raw;
  final Future<void> Function(String data)? saver;
  final String? note;
}

/// الويب: shared_preferences. الأندرويد: ملف داخل مجلد التطبيق الخاص
/// (بدون إضافات، لأن إضافة shared_preferences تتعطل في نسخة الإصدار).
Future<_Storage> _openStorage() async {
  if (kIsWeb) {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      return _Storage(
        raw: prefs.getString(_prefsKey),
        saver: (s) async {
          await prefs.setString(_prefsKey, s);
        },
      );
    } catch (e) {
      return _Storage(note: '$e');
    }
  }
  final errors = <String>[];
  final dirs = <String>[
    '${Directory.systemTemp.parent.path}/files',
    '/data/user/0/com.dukkan.dukkan/files',
  ];
  for (final d in dirs) {
    try {
      await Directory(d).create(recursive: true);
      final file = File('$d/dukkan_data.json');
      final raw = await file.exists() ? await file.readAsString() : null;
      return _Storage(
        raw: raw,
        saver: (s) async {
          final tmp = File('${file.path}.tmp');
          await tmp.writeAsString(s, flush: true);
          await tmp.rename(file.path);
        },
      );
    } catch (e) {
      errors.add('$d: $e');
    }
  }
  return _Storage(note: errors.join('\n'));
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText('Startup error:\n$message'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({super.key, required this.store, this.note});

  final AppStore store;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دكّان',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6B6B)),
        scaffoldBackgroundColor: const Color(0xFFF2F5F5),
        fontFamilyFallback: const ['Tajawal', 'Noto Sans Arabic', 'Tahoma'],
      ),
      home: Shell(store: store, note: note),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store, this.note});

  final AppStore store;
  final String? note;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  static const _items = [
    ('بيع', Icons.point_of_sale_rounded),
    ('المخزون', Icons.inventory_2_outlined),
    ('استلام بضاعة', Icons.local_shipping_outlined),
    ('التقارير', Icons.bar_chart_rounded),
    ('الإعدادات', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pages = <Widget>[
      SellPage(store: store),
      StockPage(store: store),
      ReceivePage(store: store),
      ReportPage(store: store),
      SettingsPage(store: store),
    ];
    final stack = IndexedStack(index: _index, children: pages);
    final body = Column(
      children: [
        if (widget.note != null)
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(10),
            child: Text(
              'تنبيه: التخزين غير متاح، والبيانات لن تُحفظ بعد إغلاق التطبيق.\n${widget.note}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        Expanded(child: stack),
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 840;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: ListenableBuilder(
            listenable: store,
            builder: (_, __) => Text(
              store.shopName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        body: wide
            ? Row(children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  destinations: [
                    for (final it in _items)
                      NavigationRailDestination(
                        icon: Icon(it.$2),
                        label: Text(it.$1),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ])
            : body,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  for (final it in _items)
                    NavigationDestination(icon: Icon(it.$2), label: it.$1),
                ],
              ),
      );
    });
  }
}
