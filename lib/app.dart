import 'package:corp_syncmdm/main.dart';
import 'package:corp_syncmdm/modules/dashboard/dashboard.dart';
import 'package:corp_syncmdm/modules/devices/add_device.dart';
import 'package:corp_syncmdm/modules/devices/devices.dart';
import 'package:corp_syncmdm/modules/login/tela_redefinir_senha_login.dart';
import 'package:corp_syncmdm/modules/login/tela_resetar_senha.dart';
import 'package:corp_syncmdm/modules/login/tela_verifica_codigo.dart';
import 'package:corp_syncmdm/modules/user/add_user_page.dart';
import 'package:corp_syncmdm/modules/user/user_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/widgets/custom_scroll_behavior.dart';
import 'widgets/main_scaffold.dart';
import 'package:corp_syncmdm/modules/login/tela_login.dart';
import 'theme/theme_notifier.dart';
import 'package:corp_syncmdm/modules/login/tela_verifica_codigo.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'CorpSync',
          scrollBehavior: MyCustomScrollBehavior(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            primaryColor: Color(0xFF259073),

            splashColor: Color(0xFF259073).withOpacity(0.3),
            highlightColor: Color(0xFF259073).withOpacity(0.1),
            hoverColor: Color(0xFF259073).withOpacity(0.05),

          ),
          initialRoute: '/login',
          navigatorObservers: [ClickAnalyticsObserver()],
          routes: {
            '/login': (context) => LoginPage(),
            '/dashboard': (context) => MainScaffold(
                body: DashboardPage(),
                title: 'Dashboard',
              ),
            '/usuarios': (context) => MainScaffold(
                body: UserList(),
                title: 'Lista de Usuários',
              ),
            '/usuarios/add': (context) => MainScaffold(
                body: AddUserPage(showAppBar: false),
                title: 'Adicionar Usuário',
              ),
            '/dispositivos/add': (context) => MainScaffold(
                body: AddDevicePage(),
                title: 'Adicionar Dispositivo',
              ),
            '/dispositivos': (context) => MainScaffold(
                body: DevicesPage(),
                title: 'Lista de Dispositivos',
              ),            
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/verify-reset-code':
                (context) => const VerifyResetCodePage(), 
            '/reset-password': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              final email = args['email'] as String;
              return ResetPasswordPage(email: email);
            },
          },
        );
      },
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: MyApp()),
  );
}
