import 'package:firebase_auth/firebase_auth.dart';
import '../models/perfil.dart';
import 'auth_erro.dart';
import 'hermes_api.dart';
import 'sessao.dart';

/// Login simplificado (fase de testes): sem e-mail nem cadastro.
/// O app entra como usuário anônimo do Firebase e pede ao servidor o papel:
/// sem senha = cliente; com a senha do cadeado = admin (suporte técnico).
class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static Stream<User?> get estado => _auth.authStateChanges();
  static String get uid => _auth.currentUser?.uid ?? '';

  /// Entrada em andamento. O AuthGate espera por ela antes de carregar o
  /// perfil, para não consultar antes do servidor registrar o papel.
  static Future<Perfil>? entradaEmAndamento;

  static Future<Perfil> entrar({String? senha}) {
    final f = _entrar(senha);
    entradaEmAndamento = f;
    return f;
  }

  static Future<Perfil> _entrar(String? senha) async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      final perfil = await HermesApi.instance.entrar(senha: senha);
      Sessao.perfil.value = perfil;
      return perfil;
    } on FirebaseAuthException catch (e) {
      await _auth.signOut();
      throw AuthErro(_traduzir(e.code));
    } catch (_) {
      // Senha errada ou backend fora do ar: volta para a tela de entrada.
      await _auth.signOut();
      rethrow;
    }
  }

  static Future<void> sair() async {
    Sessao.limpar();
    await _auth.signOut();
  }

  static String _traduzir(String codigo) {
    switch (codigo) {
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return 'Ative o login "Anônimo" em Authentication > Sign-in method no Firebase.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Não foi possível entrar ($codigo).';
    }
  }
}
