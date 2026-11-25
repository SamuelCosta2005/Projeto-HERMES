import 'item_estoque.dart';

/// Item + quantidade escolhidos na tela de materiais.
class LinhaSelecionada {
  final ItemEstoque item;
  final int quantidade;

  const LinhaSelecionada({required this.item, required this.quantidade});
}
