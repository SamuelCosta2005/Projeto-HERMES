import 'util.dart';

/// Sala/local de entrega (coleção compartilhada locais_eventos).
class Local {
  final String id;
  final String unidade;
  final String predio;
  final String andar;
  final String identificador;
  final int capacidadeMaxima;

  const Local({
    required this.id,
    required this.unidade,
    required this.predio,
    required this.andar,
    required this.identificador,
    required this.capacidadeMaxima,
  });

  /// Ex.: "Bloco A · Campus Demo".
  String get detalhe {
    final partes = <String>[];
    if (predio.isNotEmpty) partes.add(predio);
    if (unidade.isNotEmpty) partes.add(unidade);
    return partes.join(' · ');
  }

  factory Local.deDoc(String id, Map<String, dynamic> d) {
    return Local(
      id: id,
      unidade: lerString(d['unidade']),
      predio: lerString(d['predio']),
      andar: lerString(d['andar']),
      identificador: lerString(d['identificador'], id),
      capacidadeMaxima: lerInt(d['capacidadeMaxima']),
    );
  }
}
