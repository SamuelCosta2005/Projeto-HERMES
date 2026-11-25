import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';

class PedidosRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('pedidos_hermes');

  List<Pedido> _lista(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Pedido.deDoc(d.id, d.data())).toList();

  /// Meus pedidos. As regras exigem o filtro por solicitanteId.
  Stream<List<Pedido>> watchMeus(String uid) {
    // Ordena aqui no app (mais recentes primeiro) para não exigir índice no Firestore.
    return _col.where('solicitanteId', isEqualTo: uid).snapshots().map((s) {
      final lista = _lista(s);
      final agora = DateTime.now();
      lista.sort((a, b) => (b.criadoEm ?? agora).compareTo(a.criadoEm ?? agora));
      return lista.length > 50 ? lista.sublist(0, 50) : lista;
    });
  }

  Stream<Pedido?> watchPedido(String id) {
    return _col.doc(id).snapshots().map((d) {
      final dados = d.data();
      return dados == null ? null : Pedido.deDoc(d.id, dados);
    });
  }

  /// Fila completa de pedidos ativos. Só técnico/admin conseguem ler.
  Stream<List<Pedido>> watchAtivos() {
    // Ordena aqui no app (mais antigos primeiro) para não exigir índice no Firestore.
    return _col.where('status', whereIn: ['queued', 'inTransit', 'arrived']).snapshots().map((s) {
      final lista = _lista(s);
      final agora = DateTime.now();
      lista.sort((a, b) => (a.criadoEm ?? agora).compareTo(b.criadoEm ?? agora));
      return lista;
    });
  }
}
