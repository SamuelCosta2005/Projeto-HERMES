import 'package:flutter/foundation.dart';
import '../models/perfil.dart';

/// Quem está logado e com qual papel (preenchido depois do login).
class Sessao {
  Sessao._();

  static final ValueNotifier<Perfil?> perfil = ValueNotifier<Perfil?>(null);

  static Perfil? get atual => perfil.value;
  static void limpar() => perfil.value = null;
}
