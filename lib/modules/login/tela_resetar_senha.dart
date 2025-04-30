import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> resetPassword(String email) async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      showDialogMessage("Preencha todos os campos.");
      return;
    }

    if (password != confirmPassword) {
      showDialogMessage("As senhas não coincidem.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'http://192.168.3.112:4040/api/auth/reset-password',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'password': password}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        showDialogMessage("Senha redefinida com sucesso!", success: true);
      } else {
        final error = jsonDecode(response.body);
        showDialogMessage(error['error'] ?? "Erro ao redefinir senha.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showDialogMessage("Erro de conexão. Tente novamente.");
    }
  }

  void showDialogMessage(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(success ? "Sucesso" : "Erro"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (success) {
                    Navigator.of(context).pushReplacementNamed('/login');
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args != null ? args['email'] as String : widget.email;

    return Scaffold(
      appBar: AppBar(title: const Text("Redefinir Senha")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Nova Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirmar Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => resetPassword(email),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Redefinir Senha"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
