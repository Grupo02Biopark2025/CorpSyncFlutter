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
      final url = Uri.parse('http://192.168.3.112:4040/api/auth/verify-code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacementNamed(
          '/reset-password',
          arguments: {'email': email}, // Passando email para a próxima tela
        );
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
      appBar: AppBar(title: const Text("Verificar Código")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : verifyCode,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verificar Código"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
