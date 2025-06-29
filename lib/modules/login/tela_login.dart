import 'dart:io';

import 'package:corp_syncmdm/services/workmanager_sync.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/modules/user/user_model.dart';
import 'package:corp_syncmdm/modules/user/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cards.dart';
import 'package:corp_syncmdm/screens/qr_scanner_page.dart';
// import 'tela_redefinir_senha_login.dart';
// import 'tela_resetar_senha.dart';
import 'tela_cadastro_user.example';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  Future<void> showPermissionsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permissões Necessárias'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Para o funcionamento completo do sistema MDM, precisamos de algumas permissões:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('• Localização - Para rastrear a posição do dispositivo'),
                Text('• Armazenamento - Para ler/gravar dados'),
                Text('• Estado do telefone - Para informações do dispositivo'),
                if (Platform.isAndroid)
                  Text('• Estatísticas de uso - Para monitorar o tempo de tela'),
                SizedBox(height: 10),
                Text(
                  'Algumas permissões precisam ser ativadas manualmente nas configurações do sistema.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Conceder Permissões'),
              onPressed: () {
                Navigator.of(context).pop();
                // Chame suas funções de permissão aqui
              },
            ),
          ],
        );
      },
    );
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscureText = true;

  // Função para fazer login via API
  Future<void> loginUser() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorDialog("Por favor, insira seu email e senha.");
      return;
    }
    final url = Uri.parse('http://10.0.2.2:4040/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        final user = UserModel.fromJson(responseData['user']);
        final String token = responseData['token'];

        // Salva no provider
        Provider.of<UserProvider>(context, listen: false).setUser(user);

        // Salva o token localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // await startPeriodicSyncAfterQRScan();

        // Navega para a tela de dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } catch (e) {
        print(e);
          showErrorDialog("Erro! Contate um suporte.");
      }
    } else {
      showErrorDialog("Email ou senha inválidos. Tente novamente.");
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Erro"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 60, left: 40, right: 40),
        color: Colors.white,
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 40),
            CustomCard(
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/Logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const Center(
                    child: Text(
                      "CorpSync",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        // fontFamily: ,
                        fontSize: 28,
                        letterSpacing: 1.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Bem vindo de volta! Por favor, insira seus dados de login.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-mail",
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    keyboardType: TextInputType.text,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                  Container(
                    height: 40,
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: const Text(
                        "Esqueci a senha",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF7FDA89),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/forgot-password');
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    height: 60,
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      color: Color(0xFF259073),
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    child: SizedBox.expand(
                      child: TextButton(
                        onPressed: () {
                          loginUser();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF259073),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Entrar",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                      onPressed: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => QRScannerPage(),
                        ),
                        );
                      },
                      child: const Text(
                        "Escanear QR Code",
                        style: TextStyle(
                          color: Color(0xFF7FDA89),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}