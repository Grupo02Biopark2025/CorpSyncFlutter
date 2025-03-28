import 'package:corp_syncmdm/modules/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/widgets/custom_scroll_behavior.dart';
import 'widgets/main_scaffold.dart';
import 'package:corp_syncmdm/modules/login/tela_login.dart';
import 'theme/theme_notifier.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'CorpSync',
          scrollBehavior: MyCustomScrollBehavior(),
          debugShowCheckedModeBanner: false,
          theme: themeNotifier.currentTheme,
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginPage(),
            '/dashboard': (context) => MainScaffold(
                body: DashboardPage(),
                title: 'Dashboard',
              ),

          },
        );
      },
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(),
    ),
  );
}