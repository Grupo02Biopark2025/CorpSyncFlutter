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
  bool obscurePassword = true;
  bool obscureConfirm = true;

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
      final url = Uri.parse('http://10.0.2.2:4040/api/auth/reset-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
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
                "Redefinir senha",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: "Nova Senha",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                ),
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirmar Senha",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscureConfirm = !obscureConfirm);
                  },
                ),
              ),
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
                  onPressed: _isLoading ? null : () => resetPassword(email),
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
                                "Redefinir Senha",
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
