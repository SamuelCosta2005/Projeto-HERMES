enum Papel {
  solicitante('solicitante', 'Cliente'),
  tecnico('tecnico', 'Suporte técnico'),
  admin('admin', 'Suporte técnico (admin)'),
  robo('robo', 'Robô Hermes');

  const Papel(this.id, this.rotulo);

  final String id;
  final String rotulo;

  /// Técnico e admin formam a "equipe": recebem devolução e mexem no estoque.
  bool get ehEquipe => this == Papel.tecnico || this == Papel.admin;
  bool get ehRobo => this == Papel.robo;
  bool get ehAdmin => this == Papel.admin;

  static Papel deId(String? id) {
    for (final p in Papel.values) {
      if (p.id == id) return p;
    }
    return Papel.solicitante;
  }
}

class Perfil {
  final String uid;
  final String nome;
  final Papel papel;

  const Perfil({required this.uid, required this.nome, required this.papel});
}
