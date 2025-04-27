import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showDialogMessage("Por favor, insira seu e-mail.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://192.168.3.112:4040/api/auth/request-reset');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        showDialogMessage("E-mail enviado! Verifique sua caixa de entrada.", success: true);
      } else {
        final error = jsonDecode(response.body);
        showDialogMessage(error['error'] ?? "Erro ao solicitar redefinição.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showDialogMessage("Erro de conexão. Tente novamente.");
    }
  }

  void showDialogMessage(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? "Sucesso" : "Erro"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                Navigator.of(context).pushReplacementNamed(
                  '/verify-reset-code',
                  arguments: {'email': _emailController.text.trim()},
                );
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Senha")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Informe seu e-mail para receber o código de redefinição.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : requestPasswordReset,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enviar Código"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
