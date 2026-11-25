import 'package:firebase_core/firebase_core.dart';
import '../services/auth_erro.dart';
import '../services/hermes_exception.dart';

/// Texto amigável para qualquer erro que chegue na interface.
String mensagemDeErro(Object erro) {
  if (erro is HermesException) return erro.mensagem;
  if (erro is AuthErro) return erro.mensagem;
  if (erro is FirebaseException) {
    if (erro.code == 'permission-denied') {
      return 'Sem permissão para ver estes dados. Confira se o seu usuário tem acesso ao Hermes.';
    }
    if (erro.code == 'failed-precondition' && (erro.message ?? '').contains('index')) {
      return 'O Firestore precisa de um índice para esta consulta. Veja a seção "Índices" do README.';
    }
    if (erro.code == 'unavailable') {
      return 'Sem conexão com o servidor.';
    }
  }
  return 'Algo deu errado. Tente de novo.';
}
