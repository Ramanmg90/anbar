import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/catalog_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/notifications_page.dart';
import 'screens/scanner_screen.dart';
import 'screens/transaction_page.dart';
import 'store.dart';
import 'utils.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(ChangeNotifierProvider.value(value: store, child: const AnbarApp()));
}

class AnbarApp extends StatelessWidget {
  const AnbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'انبار پارچه‌سرا',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(seedColor: kBrand, brightness: Brightness.light),
        scaffoldBackgroundColor: kBg,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 0,
            textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            backgroundColor: Colors.white.withAlpha(150),
            side: BorderSide(color: Colors.white.withAlpha(220)),
            textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: const StadiumBorder())),
        chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          side: BorderSide(color: Colors.white.withAlpha(220)),
          backgroundColor: Colors.white.withAlpha(170),
          selectedColor: kBrand.withAlpha(40),
          showCheckmark: false,
        ),
        snackBarTheme: SnackBarThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), behavior: SnackBarBehavior.floating),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: Color(0xFF1C1917), elevation: 0, scrolledUnderElevation: 0, centerTitle: false),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pages = <Widget>[
      HomeScreen(onGoto: _go),
      const CatalogScreen(),
      ScannerScreen(active: _index == 2),
      const HistoryScreen(),
      const MoreScreen(),
    ];
    return DecoratedBox(
      decoration: kShellBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          titleSpacing: 16,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('انبار پارچه‌سرا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kBrand)),
            Text(fullDate(), style: const TextStyle(fontSize: 11, color: Color(0xFF78716C), fontWeight: FontWeight.w400)),
          ]),
          actions: [
            IconButton(
              tooltip: 'اعلان‌ها',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
              icon: Badge(
                isLabelVisible: store.unreadCount > 0,
                label: Text(toFa(store.unreadCount)),
                child: const Icon(Icons.notifications_none),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(children: [
          if (store.loadError != null)
            MaterialBanner(
              backgroundColor: Colors.red.shade50,
              content: Text(store.loadError!, style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: store.dismissError,
                  child: const Text('باشه'),
                ),
              ],
            ),
          Expanded(child: pages[_index]),
        ]),
        floatingActionButton: (_index == 0 || _index == 1 || _index == 3)
            ? Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // دکمه‌ی «+» افزودن کالای جدید، فقط در تب کالاها
                  if (_index == 1) ...[
                    GlassCircleButton(
                      icon: Icons.add,
                      tooltip: 'افزودن کالای جدید',
                      size: 58,
                      onPressed: () => openAddFabric(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                  GlassButton(
                    label: 'ثبت ورود / خروج',
                    icon: Icons.swap_vert,
                    expand: false,
                    height: 54,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionPage())),
                  ),
                ]),
              )
            : null,
        bottomNavigationBar: GlassNavBar(
          index: _index,
          onChanged: _go,
          items: const [
            (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'خانه'),
            (icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'کالاها'),
            (icon: Icons.qr_code_scanner, selectedIcon: Icons.qr_code_scanner, label: 'اسکن'),
            (icon: Icons.history, selectedIcon: Icons.history, label: 'تاریخچه'),
            (icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: 'بیشتر'),
          ],
        ),
      ),
    );
  }
}
