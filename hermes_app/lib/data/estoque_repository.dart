import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_estoque.dart';

class EstoqueRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('estoque_itens');

  /// Todos os itens (ativos e inativos), por nome. Quem decide o que mostrar é a tela.
  Stream<List<ItemEstoque>> watchItens() {
    return _col.orderBy('nome').snapshots().map(
          (s) => s.docs.map((d) => ItemEstoque.deDoc(d.id, d.data())).toList(),
        );
  }

  Stream<ItemEstoque?> watchItem(String id) {
    return _col.doc(id).snapshots().map((d) {
      final dados = d.data();
      return dados == null ? null : ItemEstoque.deDoc(d.id, dados);
    });
  }
}
