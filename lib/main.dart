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
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(DukkanApp(store: AppStore(prefs)));
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({super.key, required this.store});

  final AppStore store;

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
      home: Shell(store: store),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store});

  final AppStore store;

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
    final body = IndexedStack(index: _index, children: pages);

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
