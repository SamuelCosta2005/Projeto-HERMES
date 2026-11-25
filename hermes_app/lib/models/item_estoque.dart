import 'categoria.dart';
import 'util.dart';

class ItemEstoque {
  final String id;
  final String nome;
  final Categoria categoria;
  final bool retornavel;
  final int estoqueTotal;
  final int emUso;
  final int estoqueMinimo;
  final String unidade;
  final bool ativo;

  const ItemEstoque({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.retornavel,
    required this.estoqueTotal,
    required this.emUso,
    required this.estoqueMinimo,
    required this.unidade,
    required this.ativo,
  });

  /// Disponível = total − em uso (reservado + emprestado).
  int get disponivel => estoqueTotal - emUso;

  /// Alerta de reposição: o que dá para pedir agora está abaixo do mínimo.
  bool get estoqueBaixo => estoqueMinimo > 0 && disponivel < estoqueMinimo;

  factory ItemEstoque.deDoc(String id, Map<String, dynamic> d) {
    return ItemEstoque(
      id: id,
      nome: lerString(d['nome'], 'Sem nome'),
      categoria: Categoria.deId(lerStringOpc(d['categoria'])),
      retornavel: lerBool(d['retornavel']),
      estoqueTotal: lerInt(d['estoqueTotal']),
      emUso: lerInt(d['emUso']),
      estoqueMinimo: lerInt(d['estoqueMinimo']),
      unidade: lerString(d['unidade'], 'un'),
      ativo: lerBool(d['ativo'], true),
    );
  }
}
