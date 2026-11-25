/// Senha do admin (suporte técnico). Versão de teste, sem preocupação com
/// segurança: quem abrir o código vê a senha. Troque aqui se quiser.
const String kSenhaAdmin = '1234';

/// false = o técnico só registra devolução de item que o cliente já pediu para
/// recolher. true = também aceita devolução de item ainda "em posse".
const bool kPermitirDevolucaoSemPedido = false;

/// Para testar contra o emulador do Firebase (opcional):
///   flutter run --dart-define=USAR_EMULADOR=true --dart-define=EMULADOR_HOST=10.0.2.2
/// (10.0.2.2 é o "localhost" do emulador Android; no simulador iOS use localhost.)
const bool kUsarEmulador = bool.fromEnvironment('USAR_EMULADOR');
const String kEmuladorHost = String.fromEnvironment('EMULADOR_HOST', defaultValue: '10.0.2.2');

/// Senha de quem entra como "Robô" (o celular que manda a posição do Hermes).
/// Versão de teste, sem preocupação com segurança.
const String kSenhaRobo = '4321';
