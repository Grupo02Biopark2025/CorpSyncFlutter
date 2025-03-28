class EmailValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'E-mail não pode ser vazio';
    }
    email = email.toLowerCase();
    const String pattern =
        r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9]+\.[a-z]+";
    final RegExp regex = RegExp(pattern);

    if (!regex.hasMatch(email)) {
      return 'Formato de e-mail inválido';
    }

    return null;
  }
}
