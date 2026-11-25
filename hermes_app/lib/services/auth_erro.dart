/// Erro de login com mensagem já pronta para mostrar ao usuário.
class AuthErro implements Exception {
  final String mensagem;
  AuthErro(this.mensagem);

  @override
  String toString() => mensagem;
}
