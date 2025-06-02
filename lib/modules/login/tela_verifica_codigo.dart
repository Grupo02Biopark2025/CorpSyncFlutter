import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerifyResetCodePage extends StatefulWidget {
  const VerifyResetCodePage({Key? key}) : super(key: key);

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      showDialogMessage("Por favor, preencha todos os campos.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:4040/api/auth/verify-code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/reset-password', arguments: {'email': email});
      } else {
        final error = jsonDecode(response.body);
        showDialogMessage(error['error'] ?? "Erro ao validar o código.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showDialogMessage("Erro de conexão. Tente novamente.");
    }
  }

  void showDialogMessage(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Mensagem"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.only(top: 60, left: 40, right: 40),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/images/Logo.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "CorpSync",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: 1.0,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Verificação de Código",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Digite o código de 6 dígitos enviado para seu e-mail.",
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            Container(
              height: 60,
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: Color(0xFF259073),
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: SizedBox.expand(
                child: TextButton(
                  onPressed: _isLoading ? null : verifyCode,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF259073),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Verificar Código",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
